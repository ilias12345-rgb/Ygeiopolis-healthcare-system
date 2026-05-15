from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import subprocess
from typing import Any, Optional

import mysql.connector
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parent
SQL_DIR = PROJECT_ROOT / "sql"
DEFAULT_DATABASE = "yg_eupolis_hospital"
SOCKET_CANDIDATES = (
    "/tmp/mysql.sock",
    "/var/run/mysqld/mysqld.sock",
    "/opt/homebrew/var/mysql/mysql.sock",
)


@dataclass(frozen=True)
class DbConfig:
    host: str = "localhost"
    port: int = 3306
    user: str = "root"
    password: str = ""
    database: str = DEFAULT_DATABASE
    unix_socket: str = ""


@dataclass(frozen=True)
class QueryFile:
    number: int
    name: str
    path: Path
    output_path: Path


@dataclass
class SqlResult:
    dataframe: Optional[pd.DataFrame] = None
    affected_rows: Optional[int] = None
    message: str = ""
    label: str = ""


def query_files() -> list[QueryFile]:
    files = []
    for number in range(1, 16):
        name = f"Q{number:02d}.sql"
        files.append(
            QueryFile(
                number=number,
                name=name,
                path=SQL_DIR / name,
                output_path=SQL_DIR / f"Q{number:02d}_out.txt",
            )
        )
    return files


def get_query_file(name: str) -> QueryFile:
    for query_file in query_files():
        if query_file.name == name:
            return query_file
    raise ValueError(f"Unknown query file: {name}")


def read_query(query_file: QueryFile) -> str:
    if not query_file.path.exists():
        return ""
    return query_file.path.read_text(encoding="utf-8")


def save_query(query_file: QueryFile, sql_text: str) -> None:
    query_file.path.parent.mkdir(parents=True, exist_ok=True)
    query_file.path.write_text(sql_text, encoding="utf-8")


def first_sql_keyword(sql_text: str) -> str:
    in_block_comment = False
    for raw_line in sql_text.strip().splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if in_block_comment:
            if "*/" in line:
                in_block_comment = False
                line = line.split("*/", 1)[1].strip()
            else:
                continue
        if line.startswith("/*"):
            if "*/" in line:
                line = line.split("*/", 1)[1].strip()
            else:
                in_block_comment = True
                continue
        if line.startswith("--") or line.startswith("#"):
            continue
        return line.split(None, 1)[0].rstrip(";").lower()
    return ""


READ_ONLY_KEYWORDS = {"select", "with", "show", "describe", "desc", "explain"}
SCRIPT_ALLOWED_KEYWORDS = READ_ONLY_KEYWORDS | {"use", "set"}
DESTRUCTIVE_KEYWORDS = {
    "alter",
    "create",
    "delete",
    "drop",
    "grant",
    "insert",
    "load",
    "replace",
    "revoke",
    "truncate",
    "update",
}


def is_read_query(sql_text: str) -> bool:
    return first_sql_keyword(sql_text) in READ_ONLY_KEYWORDS


def is_safe_predefined_script(sql_text: str) -> bool:
    statements = split_sql_statements(sql_text)
    if not statements:
        return False
    for statement in statements:
        keyword = first_sql_keyword(statement)
        if keyword in DESTRUCTIVE_KEYWORDS or keyword not in SCRIPT_ALLOWED_KEYWORDS:
            return False
    return True


def mysql_cli_args(config: DbConfig, include_database: bool = False) -> list[str]:
    args = [
        "mysql",
        "--local-infile=1",
        "-h",
        config.host,
        "-P",
        str(config.port),
        "-u",
        config.user,
    ]
    if config.password:
        args.append(f"-p{config.password}")
    if config.unix_socket:
        args.extend(["--socket", config.unix_socket])
    if include_database:
        args.append(config.database)
    return args


def run_mysql_script(script_path: Path, working_dir: Path, config: DbConfig) -> subprocess.CompletedProcess[str]:
    with script_path.open("r", encoding="utf-8") as script:
        return subprocess.run(
            mysql_cli_args(config),
            stdin=script,
            cwd=working_dir,
            capture_output=True,
            text=True,
            check=False,
        )


def connect(config: DbConfig):
    connection_args = {
        "host": config.host,
        "port": config.port,
        "user": config.user,
        "password": config.password,
        "database": config.database,
        "allow_local_infile": True,
        "charset": "utf8mb4",
        "collation": "utf8mb4_unicode_ci",
    }
    if config.unix_socket:
        connection_args["unix_socket"] = config.unix_socket
    return mysql.connector.connect(
        **connection_args,
    )


def test_connection(config: DbConfig) -> str:
    conn = connect(config)
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT DATABASE(), VERSION()")
        database_name, version = cursor.fetchone()
        return f"Connected to {database_name} on MySQL/MariaDB {version}"
    finally:
        conn.close()


def split_sql_statements(sql_text: str) -> list[str]:
    return [statement.strip() for statement in sql_text.split(";") if statement.strip()]


def fetch_dataframe(sql_text: str, config: DbConfig, params: Optional[tuple[Any, ...]] = None) -> pd.DataFrame:
    if not is_read_query(sql_text):
        raise ValueError("Only read-only SELECT queries are allowed from the UI.")

    conn = connect(config)
    try:
        cursor = conn.cursor(dictionary=True)
        try:
            cursor.execute(sql_text, params or ())
            columns = [column[0] for column in cursor.description]
            return pd.DataFrame(cursor.fetchall(), columns=columns)
        finally:
            cursor.close()
    finally:
        conn.close()


def execute_sql(sql_text: str, config: DbConfig) -> SqlResult:
    sql_clean = sql_text.strip()
    if not sql_clean:
        raise ValueError("The SQL editor is empty.")

    statements = split_sql_statements(sql_clean)
    if not statements:
        raise ValueError("The SQL editor does not contain an executable statement.")

    conn = connect(config)
    try:
        cursor = conn.cursor(dictionary=True)
        try:
            affected_rows = 0
            last_dataframe: Optional[pd.DataFrame] = None
            needs_commit = False

            for statement in statements:
                keyword = first_sql_keyword(statement)
                cursor.execute(statement)
                if cursor.with_rows:
                    columns = [column[0] for column in cursor.description]
                    rows = cursor.fetchall()
                    last_dataframe = pd.DataFrame(rows, columns=columns)
                else:
                    affected_rows += max(cursor.rowcount, 0)
                    if keyword not in {"use", "set", "show", "describe", "desc", "explain"}:
                        needs_commit = True

            if needs_commit:
                conn.commit()
            if last_dataframe is not None:
                return SqlResult(
                    dataframe=last_dataframe,
                    message=f"{len(last_dataframe)} rows returned.",
                )

            return SqlResult(affected_rows=affected_rows, message=f"Affected rows: {affected_rows}")
        finally:
            cursor.close()
    finally:
        conn.close()


def execute_read_query(sql_text: str, config: DbConfig) -> SqlResult:
    sql_clean = sql_text.strip()
    if not is_read_query(sql_clean):
        raise ValueError("Expected a read query.")

    conn = connect(config)
    try:
        cursor = conn.cursor(dictionary=True)
        try:
            cursor.execute(sql_clean)
            if not cursor.with_rows:
                raise ValueError("Query did not return rows.")
            columns = [column[0] for column in cursor.description]
            rows = cursor.fetchall()
            dataframe = pd.DataFrame(rows, columns=columns)
            return SqlResult(dataframe=dataframe, message=f"{len(dataframe)} rows returned.")
        finally:
            cursor.close()
    finally:
        conn.close()


def execute_readonly_script(sql_text: str, config: DbConfig) -> list[SqlResult]:
    sql_clean = sql_text.strip()
    if not sql_clean:
        raise ValueError("The query file is empty.")
    if not is_safe_predefined_script(sql_clean):
        raise ValueError("This workspace only runs read-only predefined SQL files.")

    results: list[SqlResult] = []
    conn = connect(config)
    try:
        cursor = conn.cursor(dictionary=True)
        try:
            for statement in split_sql_statements(sql_clean):
                keyword = first_sql_keyword(statement)
                cursor.execute(statement)
                if cursor.with_rows:
                    columns = [column[0] for column in cursor.description]
                    dataframe = pd.DataFrame(cursor.fetchall(), columns=columns)
                    results.append(
                        SqlResult(
                            dataframe=dataframe,
                            message=f"{len(dataframe)} rows returned.",
                            label=keyword.upper(),
                        )
                    )
            return results
        finally:
            cursor.close()
    finally:
        conn.close()


def format_result_for_text(result: SqlResult) -> str:
    if result.dataframe is not None:
        if result.dataframe.empty:
            return "Query returned zero rows.\n"
        return result.dataframe.to_string(index=False) + "\n"
    return result.message + "\n"


def save_query_output(query_file: QueryFile, result: SqlResult) -> None:
    query_file.output_path.write_text(format_result_for_text(result), encoding="utf-8")


def detect_unix_socket() -> str:
    for candidate in SOCKET_CANDIDATES:
        if Path(candidate).exists():
            return candidate
    return ""
