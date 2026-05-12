from __future__ import annotations

from pathlib import Path
from typing import Any

import pandas as pd
import streamlit as st

from queries import (
    DbConfig,
    PROJECT_ROOT,
    SQL_DIR,
    detect_unix_socket,
    execute_sql,
    get_query_file,
    query_files,
    read_query,
    run_mysql_script,
    save_query,
    save_query_output,
    test_connection,
)


def apply_theme() -> None:
    st.markdown(
        """
        <style>
        :root {
            --surface: #ffffff;
            --surface-muted: #f4f7f9;
            --border: #d8e1e8;
            --text: #1f2933;
            --muted: #64748b;
            --accent: #0f766e;
            --accent-soft: #d9f2ee;
            --warning: #b7791f;
            --critical: #b91c1c;
        }

        .stApp {
            background: #f6f8fb;
            color: var(--text);
        }

        [data-testid="stSidebar"] {
            background: #eef4f6;
            border-right: 1px solid var(--border);
        }

        h1, h2, h3 {
            color: var(--text);
            letter-spacing: 0;
        }

        div[data-testid="stMetric"] {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 14px 16px;
        }

        div[data-testid="stMetricLabel"] {
            color: var(--muted);
        }

        div[data-testid="stMetricValue"] {
            color: var(--text);
        }

        .section-label {
            color: var(--muted);
            font-size: 0.78rem;
            font-weight: 700;
            letter-spacing: 0.04em;
            margin: 0.25rem 0 0.45rem 0;
            text-transform: uppercase;
        }

        .status-strip {
            background: var(--surface);
            border: 1px solid var(--border);
            border-left: 4px solid var(--accent);
            border-radius: 8px;
            color: var(--text);
            padding: 0.85rem 1rem;
        }

        .muted {
            color: var(--muted);
        }

        .stButton > button {
            border-radius: 6px;
            border: 1px solid var(--border);
            font-weight: 600;
        }

        .stButton > button[kind="primary"] {
            background: var(--accent);
            border-color: var(--accent);
        }

        div[data-testid="stDataFrame"] {
            border: 1px solid var(--border);
            border-radius: 8px;
            overflow: hidden;
        }
        </style>
        """,
        unsafe_allow_html=True,
    )


def connection_sidebar() -> DbConfig:
    detected_socket = detect_unix_socket()
    with st.sidebar:
        st.title("Ygeiopolis HIS")
        st.caption("Hospital information console")

        with st.expander("Database connection", expanded=True):
            host = st.text_input("Host", value="localhost")
            port = st.number_input("Port", value=3306, min_value=1, max_value=65535)
            user = st.text_input("User", value="root")
            password = st.text_input("Password", type="password")
            database = st.text_input("Database", value="yg_eupolis_hospital")
            unix_socket = st.text_input("Unix socket", value=detected_socket)

        config = DbConfig(
            host=host,
            port=int(port),
            user=user,
            password=password,
            database=database,
            unix_socket=unix_socket.strip(),
        )

        if st.button("Test connection", width="stretch"):
            try:
                st.success(test_connection(config))
            except Exception as exc:
                st.error(str(exc))

    return config


def load_dataframe(sql: str, config: DbConfig) -> pd.DataFrame:
    result = execute_sql(sql, config)
    return result.dataframe if result.dataframe is not None else pd.DataFrame()


def sql_date(value: Any) -> str:
    return str(value)[:10].replace("'", "''")


def metric_value(row: pd.Series, key: str, fallback: str = "0") -> str:
    value = row.get(key)
    if pd.isna(value):
        return fallback
    if isinstance(value, float):
        return f"{value:,.1f}" if value % 1 else f"{value:,.0f}"
    return f"{value:,}" if isinstance(value, int) else str(value)


def render_table(title: str, dataframe: pd.DataFrame, height: int = 300) -> None:
    st.markdown(f'<div class="section-label">{title}</div>', unsafe_allow_html=True)
    if dataframe.empty:
        st.info("No records for the selected context.")
        return
    st.dataframe(dataframe, width="stretch", height=height)


def load_operational_dates(config: DbConfig) -> list[str]:
    dataframe = load_dataframe(
        """
        SELECT activity_date
        FROM (
            SELECT DISTINCT shift_date AS activity_date
            FROM department_shift
        ) dates
        WHERE activity_date IS NOT NULL
        ORDER BY activity_date DESC
        LIMIT 90;
        """,
        config,
    )
    if dataframe.empty:
        return []
    return [sql_date(value) for value in dataframe["activity_date"].tolist()]


def render_dashboard(config: DbConfig) -> None:
    st.title("Hospital Operations")
    st.caption("Live operational view from the Ygeiopolis relational database.")

    try:
        operational_dates = load_operational_dates(config)
    except Exception as exc:
        st.error("Database is not ready. Check the connection or run the setup script.")
        with st.expander("Connection details"):
            st.code(str(exc))
        return

    if not operational_dates:
        st.warning("No operational data found. Run `sql/setup.sql` from the Database Setup tab.")
        return

    selected_date = st.selectbox("Operational date", operational_dates, index=0)
    date_literal = sql_date(selected_date)

    kpis = load_dataframe(
        f"""
        SELECT
            (SELECT COUNT(*) FROM hospitalization WHERE DATE(admission_ts) = '{date_literal}') AS admissions_on_date,
            (SELECT ROUND(
                100 * SUM(CASE WHEN bed_status = 'OCCUPIED' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1
             ) FROM bed) AS bed_occupancy_pct,
            (SELECT COUNT(*) FROM emergency_visit WHERE status = 'WAITING') AS emergency_waiting,
            (SELECT COUNT(*) FROM procedure_event WHERE DATE(start_ts) = '{date_literal}') AS procedures_on_date,
            (SELECT COUNT(*) FROM prescription
              WHERE start_datetime <= '{date_literal} 23:59:59'
                AND (end_datetime IS NULL OR end_datetime >= '{date_literal} 00:00:00')
            ) AS active_prescriptions,
            (SELECT CONCAT(
                SUM(CASE WHEN shift_status = 'VALID' THEN 1 ELSE 0 END), '/', COUNT(*)
             ) FROM department_shift WHERE shift_date = '{date_literal}') AS valid_shifts;
        """,
        config,
    )
    row = kpis.iloc[0] if not kpis.empty else pd.Series(dtype=object)

    col1, col2, col3, col4, col5, col6 = st.columns(6)
    col1.metric("Admissions", metric_value(row, "admissions_on_date"))
    col2.metric("Bed Occupancy", f"{metric_value(row, 'bed_occupancy_pct')}%")
    col3.metric("Emergency Queue", metric_value(row, "emergency_waiting"))
    col4.metric("Procedures", metric_value(row, "procedures_on_date"))
    col5.metric("Active Prescriptions", metric_value(row, "active_prescriptions"))
    col6.metric("Valid Shifts", metric_value(row, "valid_shifts", "0/0"))

    st.markdown(
        f'<div class="status-strip">Operational date: <strong>{date_literal}</strong> '
        f'<span class="muted">| Database: {config.database}</span></div>',
        unsafe_allow_html=True,
    )

    bed_census = load_dataframe(
        f"""
        SELECT
            d.department_name AS Department,
            d.bed_capacity AS Capacity,
            COALESCE(h.admissions, 0) AS Admissions,
            COALESCE(b.total_beds, 0) AS Beds,
            COALESCE(b.occupied_beds, 0) AS Occupied,
            COALESCE(b.available_beds, 0) AS Available,
            COALESCE(b.maintenance_beds, 0) AS Maintenance,
            COALESCE(b.occupancy_pct, 0) AS Occupancy_Pct
        FROM department d
        LEFT JOIN (
            SELECT department_id, COUNT(*) AS admissions
            FROM hospitalization
            WHERE DATE(admission_ts) = '{date_literal}'
            GROUP BY department_id
        ) h ON h.department_id = d.department_id
        LEFT JOIN (
            SELECT
                department_id,
                COUNT(*) AS total_beds,
                SUM(CASE WHEN bed_status = 'OCCUPIED' THEN 1 ELSE 0 END) AS occupied_beds,
                SUM(CASE WHEN bed_status = 'AVAILABLE' THEN 1 ELSE 0 END) AS available_beds,
                SUM(CASE WHEN bed_status = 'MAINTENANCE' THEN 1 ELSE 0 END) AS maintenance_beds,
                ROUND(
                    100 * SUM(CASE WHEN bed_status = 'OCCUPIED' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
                    1
                ) AS occupancy_pct
            FROM bed
            GROUP BY department_id
        ) b ON b.department_id = d.department_id
        ORDER BY Occupancy_Pct DESC, Department;
        """,
        config,
    )

    shift_coverage = load_dataframe(
        f"""
        SELECT
            department_name AS Department,
            shift_type AS Shift,
            shift_status AS Status,
            COUNT(*) AS Staff,
            SUM(CASE WHEN personnel_type = 'DOCTOR' THEN 1 ELSE 0 END) AS Doctors,
            SUM(CASE WHEN personnel_type = 'NURSE' THEN 1 ELSE 0 END) AS Nurses,
            SUM(CASE WHEN personnel_type = 'ADMIN' THEN 1 ELSE 0 END) AS Administrative
        FROM shift_staff
        WHERE shift_date = '{date_literal}'
        GROUP BY department_name, shift_type, shift_status
        ORDER BY Department, FIELD(Shift, 'MORNING', 'AFTERNOON', 'NIGHT');
        """,
        config,
    )

    col_a, col_b = st.columns([1.15, 0.85])
    with col_a:
        render_table("Bed And Admission Snapshot", bed_census, height=330)
    with col_b:
        render_table("Shift Coverage", shift_coverage, height=330)

    procedures = load_dataframe(
        f"""
        SELECT
            DATE_FORMAT(start_ts, '%H:%i') AS Start,
            DATE_FORMAT(end_ts, '%H:%i') AS End,
            place_name AS Location,
            procedure_category AS Category,
            LEFT(procedure_name, 72) AS Procedure_Name,
            CONCAT(first_name, ' ', last_name) AS Lead_Doctor,
            actual_duration_min AS Minutes
        FROM doctor_procedure
        WHERE DATE(start_ts) = '{date_literal}'
        ORDER BY start_ts
        LIMIT 20;
        """,
        config,
    )

    emergency_queue = load_dataframe(
        f"""
        SELECT
            DATE_FORMAT(ev.arrival_ts, '%H:%i') AS Arrival,
            ev.emergency_level AS Priority,
            ev.status AS Status,
            CONCAT(p.first_name, ' ', p.last_name) AS Patient,
            COALESCE(d.department_name, 'Not referred') AS Department
        FROM emergency_visit ev
        JOIN patient p ON p.patient_amka = ev.patient_amka
        LEFT JOIN department d ON d.department_id = ev.referred_department_id
        WHERE DATE(ev.arrival_ts) = '{date_literal}'
        ORDER BY ev.emergency_level ASC, ev.arrival_ts ASC
        LIMIT 20;
        """,
        config,
    )

    col_c, col_d = st.columns(2)
    with col_c:
        render_table("Procedure Schedule", procedures, height=360)
    with col_d:
        render_table("Emergency Department Queue", emergency_queue, height=360)

    monitors = load_dataframe(
        """
        SELECT 'Processing shifts' AS Monitor, COUNT(*) AS Open_Items
        FROM department_shift
        WHERE shift_status = 'PROCESSING'
        UNION ALL
        SELECT 'Beds in maintenance' AS Monitor, COUNT(*) AS Open_Items
        FROM bed
        WHERE bed_status = 'MAINTENANCE'
        UNION ALL
        SELECT 'Open emergency queue' AS Monitor, COUNT(*) AS Open_Items
        FROM emergency_visit
        WHERE status = 'WAITING'
        UNION ALL
        SELECT 'Missing discharge diagnosis' AS Monitor, COUNT(*) AS Open_Items
        FROM hospitalization
        WHERE discharge_ts IS NOT NULL AND discharge_icd10_code IS NULL;
        """,
        config,
    )
    render_table("Operational Monitors", monitors, height=190)


def render_setup(config: DbConfig) -> None:
    st.title("Database Setup")
    st.caption("Run the official setup script with relative project paths.")

    col1, col2 = st.columns(2)
    with col1:
        working_dir_text = st.text_input("Working directory", value=str(PROJECT_ROOT))
    with col2:
        setup_script_text = st.text_input("Setup script", value=str(SQL_DIR / "setup.sql"))

    st.warning("Setup recreates `yg_eupolis_hospital` and reloads all CSV data.")

    if st.button("Run setup.sql", type="primary"):
        working_dir = Path(working_dir_text).expanduser()
        setup_script = Path(setup_script_text).expanduser()

        if not working_dir.exists():
            st.error(f"Working directory does not exist: {working_dir}")
            return
        if not setup_script.exists():
            st.error(f"Setup script does not exist: {setup_script}")
            return

        with st.spinner("Loading database..."):
            result = run_mysql_script(setup_script, working_dir, config)

        if result.returncode == 0:
            st.success("Database setup completed.")
        else:
            st.error(f"Setup failed with exit code {result.returncode}.")

        if result.stdout:
            st.text_area("MySQL output", result.stdout, height=260)
        if result.stderr:
            st.text_area("MySQL errors", result.stderr, height=180)


def render_queries(config: DbConfig) -> None:
    st.title("SQL Workspace")
    st.caption("Maintain and run the required Q01-Q15 SQL files.")

    selected_name = st.selectbox("Query file", [query.name for query in query_files()])
    query_file = get_query_file(selected_name)

    current_sql = read_query(query_file)
    notes_key = f"notes_{query_file.name}"
    editor_key = f"editor_{query_file.name}"

    st.text_area(
        "Requirement",
        key=notes_key,
        height=80,
        placeholder="Write the query requirement in plain language.",
    )
    sql_text = st.text_area("SQL", value=current_sql, height=340, key=editor_key)

    col1, col2, col3, _ = st.columns([1, 1, 1, 5])
    save_clicked = col1.button("Save SQL", width="stretch")
    run_clicked = col2.button("Run", type="primary", width="stretch")
    save_output_clicked = col3.button("Save Output", width="stretch")

    if save_clicked:
        save_query(query_file, sql_text)
        st.success(f"Saved `{query_file.path.relative_to(PROJECT_ROOT)}`")

    result_key = f"result_{query_file.name}"
    if run_clicked:
        try:
            with st.spinner("Running query..."):
                result = execute_sql(sql_text, config)
            st.session_state[result_key] = result
            st.success(result.message)
        except Exception as exc:
            st.session_state.pop(result_key, None)
            st.error(str(exc))

    result = st.session_state.get(result_key)
    if result is not None:
        if result.dataframe is not None:
            st.dataframe(result.dataframe, width="stretch")
        else:
            st.info(result.message)

    if save_output_clicked:
        result = st.session_state.get(result_key)
        if result is None:
            st.error("Run the query first, then save its output.")
        else:
            save_query_output(query_file, result)
            st.success(f"Saved `{query_file.output_path.relative_to(PROJECT_ROOT)}`")


def render_app() -> None:
    st.set_page_config(page_title="Ygeiopolis HIS", layout="wide")
    apply_theme()

    config = connection_sidebar()

    dashboard_tab, setup_tab, query_tab = st.tabs(["Operations", "Database Setup", "SQL Workspace"])
    with dashboard_tab:
        render_dashboard(config)
    with setup_tab:
        render_setup(config)
    with query_tab:
        render_queries(config)
