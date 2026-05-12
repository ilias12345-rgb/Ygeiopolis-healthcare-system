from pathlib import Path
import subprocess

import mysql.connector
import pandas as pd
import streamlit as st


PROJECT_ROOT = Path(__file__).resolve().parent
SQL_DIR = PROJECT_ROOT / "sql"
DEFAULT_DB = "yg_eupolis_hospital"


def query_file_names():
    return [f"Q{i:02d}.sql" for i in range(1, 16)]


def mysql_args(host, port, user, password):
    args = ["mysql", "--local-infile=1", "-h", host, "-P", str(port), "-u", user]
    if password:
        args.append(f"-p{password}")
    return args


def run_mysql_script(script_path, working_dir, host, port, user, password):
    with open(script_path, "r", encoding="utf-8") as script:
        return subprocess.run(
            mysql_args(host, port, user, password),
            stdin=script,
            cwd=working_dir,
            capture_output=True,
            text=True,
            check=False,
        )


def connect(host, port, user, password, database=DEFAULT_DB):
    return mysql.connector.connect(
        host=host,
        port=port,
        user=user,
        password=password,
        database=database,
        allow_local_infile=True,
    )


def execute_sql(sql_text, host, port, user, password):
    sql_clean = sql_text.strip()
    if not sql_clean:
        raise ValueError("The SQL editor is empty.")

    first_word = sql_clean.split(None, 1)[0].lower()
    read_only = first_word in {"select", "with", "show", "describe", "explain"}

    conn = connect(host, port, user, password)
    try:
        if read_only:
            return pd.read_sql(sql_clean, conn), None

        cursor = conn.cursor()
        statements = [stmt.strip() for stmt in sql_clean.split(";") if stmt.strip()]
        affected = 0
        for statement in statements:
            cursor.execute(statement)
            affected += max(cursor.rowcount, 0)
        conn.commit()
        return None, affected
    finally:
        conn.close()


st.set_page_config(page_title="Ygeiopolis DB", layout="wide")
st.title("Ygeiopolis Database Helper")

with st.sidebar:
    st.header("MySQL Connection")
    host = st.text_input("Host", value="localhost")
    port = st.number_input("Port", value=3306, min_value=1, max_value=65535)
    user = st.text_input("User", value="root")
    password = st.text_input("Password", type="password")
    st.caption("Leave password empty if your local MySQL root user has no password.")

setup_tab, query_tab = st.tabs(["Database Setup", "Q01-Q15 Queries"])

with setup_tab:
    st.subheader("Run Database Setup")
    st.write(
        "This runs `sql/setup.sql`, which recreates the database, loads the CSV files, "
        "and runs validation. Start it from the project root when using local `data/`, "
        "or from a generated bundle root when using `hospital_dataset_bundle`."
    )

    working_dir_text = st.text_input("Working directory", value=str(PROJECT_ROOT))
    setup_script_text = st.text_input("Setup script", value=str(SQL_DIR / "setup.sql"))

    st.warning("Running setup drops and recreates the `yg_eupolis_hospital` database.")
    if st.button("Run setup.sql"):
        working_dir = Path(working_dir_text).expanduser()
        setup_script = Path(setup_script_text).expanduser()
        if not working_dir.exists():
            st.error(f"Working directory does not exist: {working_dir}")
        elif not setup_script.exists():
            st.error(f"Setup script does not exist: {setup_script}")
        else:
            with st.spinner("Running MySQL setup..."):
                result = run_mysql_script(setup_script, working_dir, host, int(port), user, password)
            if result.returncode == 0:
                st.success("Setup completed successfully.")
            else:
                st.error(f"Setup failed with exit code {result.returncode}.")
            if result.stdout:
                st.text_area("MySQL output", result.stdout, height=240)
            if result.stderr:
                st.text_area("MySQL errors", result.stderr, height=180)

with query_tab:
    st.subheader("Write, Save, And Run SQL Queries")
    st.write(
        "Use the description box for the query idea, then write the SQL translation in the editor. "
        "The app does not call an AI service; it keeps the query files organized and runs them."
    )

    selected_file = st.selectbox("Query file", query_file_names())
    query_path = SQL_DIR / selected_file
    current_sql = query_path.read_text(encoding="utf-8") if query_path.exists() else ""

    st.text_area("Query description / notes", height=80, key=f"notes_{selected_file}")
    sql_text = st.text_area("SQL editor", value=current_sql, height=280)

    col1, col2, col3 = st.columns([1, 1, 4])
    with col1:
        save_clicked = st.button("Save query")
    with col2:
        run_clicked = st.button("Run query")

    if save_clicked:
        query_path.write_text(sql_text, encoding="utf-8")
        st.success(f"Saved {query_path.relative_to(PROJECT_ROOT)}")

    if run_clicked:
        try:
            with st.spinner("Running query..."):
                df, affected = execute_sql(sql_text, host, int(port), user, password)
            if df is not None:
                st.dataframe(df, use_container_width=True)
                st.caption(f"{len(df)} rows returned.")
            else:
                st.success(f"Query executed. Affected rows: {affected}")
        except Exception as exc:
            st.error(str(exc))
