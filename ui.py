from __future__ import annotations

from html import escape
from numbers import Number
from pathlib import Path
import re
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
            --surface-muted: #f4f8fb;
            --sidebar: #f8fbfd;
            --border: #d9e5ec;
            --text: #172033;
            --muted: #64748b;
            --accent: #0f766e;
            --accent-strong: #0b5f6a;
            --accent-soft: #dff5f1;
            --blue: #3157d5;
            --blue-soft: #e8edff;
            --warning: #b7791f;
            --critical: #b91c1c;
            --shadow: 0 10px 30px rgba(23, 32, 51, 0.07);
        }

        .stApp {
            background:
                radial-gradient(circle at top left, rgba(49, 87, 213, 0.08), transparent 28rem),
                linear-gradient(180deg, #f7fbfd 0%, #f4f7fb 100%);
            color: var(--text);
        }

        [data-testid="stSidebar"] {
            background: var(--sidebar);
            border-right: 1px solid var(--border);
        }

        [data-testid="stSidebar"] [data-testid="stSidebarContent"] {
            padding-top: 1.25rem;
        }

        h1, h2, h3 {
            color: var(--text);
            letter-spacing: 0;
        }

        h1 {
            font-size: 1.8rem;
            margin-bottom: 0.25rem;
        }

        div[data-testid="stMetric"] {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 14px 16px;
            box-shadow: var(--shadow);
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
            margin: 1rem 0 0.45rem 0;
            text-transform: uppercase;
        }

        .page-header {
            align-items: center;
            background: rgba(255, 255, 255, 0.78);
            border: 1px solid var(--border);
            border-radius: 8px;
            box-shadow: var(--shadow);
            display: flex;
            justify-content: space-between;
            margin-bottom: 1rem;
            padding: 1rem 1.1rem;
        }

        .page-eyebrow {
            color: var(--accent-strong);
            font-size: 0.76rem;
            font-weight: 800;
            letter-spacing: 0.06em;
            text-transform: uppercase;
        }

        .page-header h1 {
            margin: 0.1rem 0 0 0;
        }

        .page-meta {
            color: var(--muted);
            font-size: 0.82rem;
            text-align: right;
        }

        .status-strip {
            background: var(--surface);
            border: 1px solid var(--border);
            border-left: 4px solid var(--accent);
            border-radius: 8px;
            color: var(--text);
            margin: 0.75rem 0 0.5rem 0;
            padding: 0.85rem 1rem;
        }

        .sidebar-brand {
            align-items: center;
            background: linear-gradient(135deg, var(--accent-strong), var(--blue));
            border-radius: 8px;
            color: #ffffff;
            display: flex;
            gap: 0.75rem;
            margin: 0 0 1rem 0;
            padding: 0.85rem;
        }

        .brand-mark {
            align-items: center;
            background: rgba(255, 255, 255, 0.18);
            border: 1px solid rgba(255, 255, 255, 0.32);
            border-radius: 8px;
            display: flex;
            font-size: 1rem;
            font-weight: 900;
            height: 2.25rem;
            justify-content: center;
            width: 2.25rem;
        }

        .brand-name {
            display: block;
            font-size: 0.95rem;
            font-weight: 800;
            line-height: 1.1;
        }

        .brand-subtitle {
            color: rgba(255, 255, 255, 0.78);
            display: block;
            font-size: 0.76rem;
            line-height: 1.25;
            margin-top: 0.2rem;
        }

        .sidebar-section-title {
            color: var(--muted);
            font-size: 0.72rem;
            font-weight: 800;
            letter-spacing: 0.07em;
            margin: 1rem 0 0.35rem 0;
            text-transform: uppercase;
        }

        .sidebar-status {
            background: #ffffff;
            border: 1px solid var(--border);
            border-radius: 8px;
            margin-top: 0.75rem;
            padding: 0.8rem 0.9rem;
        }

        .sidebar-status strong {
            color: var(--text);
            display: block;
            font-size: 0.9rem;
            margin-bottom: 0.25rem;
        }

        .sidebar-status span {
            color: var(--muted);
            display: block;
            font-size: 0.78rem;
            line-height: 1.45;
        }

        .health-ok {
            color: var(--accent);
            font-weight: 700;
        }

        .health-warn {
            color: var(--warning);
            font-weight: 700;
        }

        [data-testid="stSidebar"] div[role="radiogroup"] label {
            background: #ffffff;
            border: 1px solid transparent;
            border-radius: 8px;
            margin: 0.18rem 0;
            padding: 0.35rem 0.45rem;
        }

        [data-testid="stSidebar"] div[role="radiogroup"] label:hover {
            border-color: var(--border);
        }

        [data-testid="stSidebar"] div[role="radiogroup"] label:has(input:checked) {
            background: var(--blue-soft);
            border-color: rgba(49, 87, 213, 0.22);
        }

        .query-status-grid {
            display: grid;
            gap: 0.45rem;
            grid-template-columns: repeat(auto-fit, minmax(110px, 1fr));
            margin: 0.75rem 0 1rem 0;
        }

        .query-status {
            background: #ffffff;
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 0.6rem 0.7rem;
        }

        .query-status strong {
            color: var(--text);
            display: block;
            font-size: 0.85rem;
        }

        .query-status span {
            color: var(--muted);
            display: block;
            font-size: 0.72rem;
            margin-top: 0.15rem;
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


def render_page_header(title: str, section: str, meta: str = "") -> None:
    st.markdown(
        f"""
        <div class="page-header">
            <div>
                <div class="page-eyebrow">{escape(section)}</div>
                <h1>{escape(title)}</h1>
            </div>
            <div class="page-meta">{escape(meta)}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def render_sidebar_brand() -> None:
    st.markdown(
        """
        <div class="sidebar-brand">
            <div class="brand-mark">Y+</div>
            <div>
                <span class="brand-name">Ygeiopolis HIS</span>
                <span class="brand-subtitle">Clinical Operations</span>
            </div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def connection_sidebar() -> DbConfig:
    detected_socket = detect_unix_socket()
    with st.sidebar:
        render_sidebar_brand()

        st.markdown('<div class="sidebar-section-title">Navigation</div>', unsafe_allow_html=True)
        module = st.radio(
            "Menu",
            ["Operations", "Patient Records", "Database Setup", "SQL Workspace"],
            label_visibility="collapsed",
        )
        st.session_state["module"] = module

        st.markdown('<div class="sidebar-section-title">System Access</div>', unsafe_allow_html=True)
        with st.expander("Database connection", expanded=False):
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

        st.markdown('<div class="sidebar-section-title">Data Status</div>', unsafe_allow_html=True)
        render_sidebar_status(config)

    return config


def load_dataframe(sql: str, config: DbConfig) -> pd.DataFrame:
    result = execute_sql(sql, config)
    return result.dataframe if result.dataframe is not None else pd.DataFrame()


def sql_text(value: Any) -> str:
    return str(value).replace("'", "''")


def sql_date(value: Any) -> str:
    return sql_text(str(value)[:10])


def metric_value(row: pd.Series, key: str, fallback: str = "0") -> str:
    value = row.get(key)
    if pd.isna(value):
        return fallback
    if isinstance(value, Number) and not isinstance(value, bool):
        number = float(value)
        return f"{number:,.1f}" if number % 1 else f"{number:,.0f}"
    return str(value)


def load_sidebar_status(config: DbConfig) -> pd.DataFrame:
    return load_dataframe(
        """
        SELECT
            (SELECT COUNT(*) FROM department) AS departments,
            (SELECT COUNT(*) FROM patient) AS patients,
            (SELECT COUNT(*) FROM personnel) AS staff,
            (SELECT COUNT(*) FROM hospitalization) AS hospitalizations,
            (SELECT MAX(shift_date) FROM department_shift) AS latest_shift_date;
        """,
        config,
    )


def render_sidebar_status(config: DbConfig) -> None:
    try:
        status = load_sidebar_status(config)
    except Exception:
        st.markdown(
            """
            <div class="sidebar-status">
                <strong><span class="health-warn">Database offline</span></strong>
                <span>Use Database Setup after MySQL is running.</span>
            </div>
            """,
            unsafe_allow_html=True,
        )
        return

    if status.empty:
        return

    row = status.iloc[0]
    st.markdown(
        f"""
        <div class="sidebar-status">
            <strong><span class="health-ok">Database online</span></strong>
            <span>{escape(config.database)}</span>
            <span>{metric_value(row, "patients")} patients | {metric_value(row, "staff")} staff</span>
            <span>{metric_value(row, "departments")} departments | {metric_value(row, "hospitalizations")} hospitalizations</span>
            <span>Latest roster: {escape(metric_value(row, "latest_shift_date", "N/A"))}</span>
        </div>
        """,
        unsafe_allow_html=True,
    )


def load_departments(config: DbConfig) -> list[str]:
    dataframe = load_dataframe(
        """
        SELECT department_name
        FROM department
        ORDER BY department_name;
        """,
        config,
    )
    if dataframe.empty:
        return []
    return [str(value) for value in dataframe["department_name"].tolist()]


def department_filter(alias: str, selected_department: str) -> str:
    if selected_department == "All departments":
        return ""
    return f" AND {alias}.department_name = '{sql_text(selected_department)}'"


def department_where(alias: str, selected_department: str) -> str:
    if selected_department == "All departments":
        return ""
    return f" WHERE {alias}.department_name = '{sql_text(selected_department)}'"


def render_table(title: str, dataframe: pd.DataFrame, height: int = 300) -> None:
    st.markdown(f'<div class="section-label">{title}</div>', unsafe_allow_html=True)
    if dataframe.empty:
        st.info("No records for the selected context.")
        return
    st.dataframe(dataframe, width="stretch", height=height)


def render_query_inventory() -> None:
    rows = []
    for query_file in query_files():
        sql_body = read_query(query_file).strip()
        sql_ready = bool(sql_body) and not sql_body.startswith("-- TODO")
        output_text = query_file.output_path.read_text(encoding="utf-8").strip() if query_file.output_path.exists() else ""
        output_ready = bool(output_text) and not output_text.startswith("TODO:")
        rows.append(
            {
                "Query": query_file.name,
                "SQL": "Ready" if sql_ready else "TODO",
                "Output": "Saved" if output_ready else "Pending",
            }
        )

    status_df = pd.DataFrame(rows)
    ready_count = int((status_df["SQL"] == "Ready").sum())
    saved_count = int((status_df["Output"] == "Saved").sum())
    pending_count = len(status_df) - saved_count

    metric_cols = st.columns(3)
    metric_cols[0].metric("Queries Ready", f"{ready_count}/15")
    metric_cols[1].metric("Outputs Saved", f"{saved_count}/15")
    metric_cols[2].metric("Pending Outputs", pending_count)
    st.progress(saved_count / max(len(status_df), 1))
    st.dataframe(status_df, width="stretch", hide_index=True, height=220)


SET_PARAMETER_PATTERN = re.compile(r"(?im)^\s*SET\s+(@[A-Za-z0-9_]+)\s*=\s*(.+?)\s*;\s*$")


def parse_query_parameters(sql: str) -> list[dict[str, Any]]:
    parameters: list[dict[str, Any]] = []
    seen = set()
    for match in SET_PARAMETER_PATTERN.finditer(sql):
        variable = match.group(1)
        if variable in seen:
            continue
        raw_value = match.group(2).strip()
        quoted = len(raw_value) >= 2 and raw_value.startswith("'") and raw_value.endswith("'")
        default_value = raw_value[1:-1].replace("''", "'") if quoted else raw_value
        parameters.append(
            {
                "variable": variable,
                "default_value": default_value,
                "quoted": quoted,
            }
        )
        seen.add(variable)
    return parameters


def format_parameter_value(value: str, quoted: bool) -> str:
    cleaned = value.strip()
    if quoted:
        return f"'{sql_text(cleaned)}'"
    return cleaned or "NULL"


def apply_query_parameters(sql: str, values: dict[str, dict[str, Any]]) -> str:
    def replace(match: re.Match[str]) -> str:
        variable = match.group(1)
        if variable not in values:
            return match.group(0)
        formatted = format_parameter_value(values[variable]["value"], values[variable]["quoted"])
        return f"SET {variable} = {formatted};"

    return SET_PARAMETER_PATTERN.sub(replace, sql)


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
    render_page_header("Hospital Operations", "Operations", "Beds | Rosters | ED | Procedures")

    try:
        operational_dates = load_operational_dates(config)
    except Exception as exc:
        st.error("Database is not ready. Check the connection or run the setup script.")
        with st.expander("Connection details"):
            st.code(str(exc))
        return

    if not operational_dates:
        st.warning("No operational data found. Run install/load/validation from the Database Setup tab.")
        return

    control_col1, control_col2 = st.columns([1, 1])
    with control_col1:
        selected_date = st.selectbox("Operational date", operational_dates, index=0)
    with control_col2:
        departments = ["All departments"] + load_departments(config)
        selected_department = st.selectbox("Department scope", departments)

    date_literal = sql_date(selected_date)
    dept_and = department_filter("d", selected_department)
    shift_dept_and = ""
    if selected_department != "All departments":
        shift_dept_and = f" AND department_name = '{sql_text(selected_department)}'"

    kpis = load_dataframe(
        f"""
        SELECT
            (SELECT COUNT(*)
             FROM hospitalization h
             JOIN department d ON d.department_id = h.department_id
             WHERE DATE(h.admission_ts) = '{date_literal}' {dept_and}) AS admissions_on_date,
            (SELECT ROUND(
                100 * SUM(CASE WHEN b.bed_status = 'OCCUPIED' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1
             )
             FROM bed b
             JOIN department d ON d.department_id = b.department_id
             WHERE 1 = 1 {dept_and}) AS bed_occupancy_pct,
            (SELECT COUNT(*)
             FROM emergency_visit ev
             LEFT JOIN department d ON d.department_id = ev.referred_department_id
             WHERE ev.status = 'WAITING' {dept_and}) AS emergency_waiting,
            (SELECT COUNT(*)
             FROM procedure_event pe
             JOIN hospitalization h ON h.hosp_id = pe.hosp_id
             JOIN department d ON d.department_id = h.department_id
             WHERE DATE(pe.start_ts) = '{date_literal}' {dept_and}) AS procedures_on_date,
            (SELECT COUNT(*) FROM prescription
             JOIN hospitalization h ON h.hosp_id = prescription.hosp_id
             JOIN department d ON d.department_id = h.department_id
             WHERE start_datetime <= '{date_literal} 23:59:59'
                AND (end_datetime IS NULL OR end_datetime >= '{date_literal} 00:00:00') {dept_and}
            ) AS active_prescriptions,
            (SELECT CONCAT(
                COALESCE(SUM(CASE WHEN ds.shift_status = 'VALID' THEN 1 ELSE 0 END), 0), '/', COUNT(*)
             )
             FROM department_shift ds
             JOIN department d ON d.department_id = ds.department_id
             WHERE ds.shift_date = '{date_literal}' {dept_and}) AS valid_shifts;
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
        f'<span class="muted">| Scope: {escape(selected_department)} | Database: {escape(config.database)}</span></div>',
        unsafe_allow_html=True,
    )

    activity = load_dataframe(
        f"""
        SELECT
            (SELECT COUNT(*)
             FROM hospitalization h
             JOIN department d ON d.department_id = h.department_id
             WHERE DATE(h.discharge_ts) = '{date_literal}' {dept_and}) AS discharges_on_date,
            (SELECT COUNT(*)
             FROM lab_test lt
             JOIN hospitalization h ON h.hosp_id = lt.hosp_id
             JOIN department d ON d.department_id = h.department_id
             WHERE DATE(lt.test_datetime) = '{date_literal}' {dept_and}) AS lab_orders_on_date,
            (SELECT ROUND(AVG(TIMESTAMPDIFF(MINUTE, ev.arrival_ts, ev.service_start_ts)), 0)
             FROM emergency_visit ev
             LEFT JOIN department d ON d.department_id = ev.referred_department_id
             WHERE DATE(ev.arrival_ts) = '{date_literal}'
               AND ev.service_start_ts IS NOT NULL {dept_and}) AS avg_ed_wait_min,
            (SELECT ROUND(AVG(he.overall_experience_score), 1)
             FROM hospitalization_evaluation he
             JOIN hospitalization h ON h.hosp_id = he.hosp_id
             JOIN department d ON d.department_id = h.department_id
             WHERE 1 = 1 {dept_and}) AS avg_experience_score;
        """,
        config,
    )
    activity_row = activity.iloc[0] if not activity.empty else pd.Series(dtype=object)

    act1, act2, act3, act4 = st.columns(4)
    act1.metric("Discharges", metric_value(activity_row, "discharges_on_date"))
    act2.metric("Lab Orders", metric_value(activity_row, "lab_orders_on_date"))
    act3.metric("Avg ED Wait", f"{metric_value(activity_row, 'avg_ed_wait_min', 'N/A')} min")
    act4.metric("Patient Experience", f"{metric_value(activity_row, 'avg_experience_score', 'N/A')}/5")

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
        {department_where("d", selected_department)}
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
        WHERE shift_date = '{date_literal}' {shift_dept_and}
        GROUP BY department_name, shift_type, shift_status
        ORDER BY Department, FIELD(Shift, 'MORNING', 'AFTERNOON', 'NIGHT');
        """,
        config,
    )

    staff_mix = load_dataframe(
        f"""
        SELECT
            personnel_type AS Staff_Type,
            COUNT(*) AS Assignments
        FROM shift_staff
        WHERE shift_date = '{date_literal}' {shift_dept_and}
        GROUP BY personnel_type
        ORDER BY FIELD(personnel_type, 'DOCTOR', 'NURSE', 'ADMIN');
        """,
        config,
    )

    col_a, col_b = st.columns([1.15, 0.85])
    with col_a:
        render_table("Bed And Admission Snapshot", bed_census, height=330)
    with col_b:
        render_table("Shift Coverage", shift_coverage, height=330)
        if not staff_mix.empty:
            st.markdown('<div class="section-label">Staff Mix</div>', unsafe_allow_html=True)
            st.bar_chart(staff_mix.set_index("Staff_Type"), height=220)

    procedures = load_dataframe(
        f"""
        SELECT
            DATE_FORMAT(start_ts, '%H:%i') AS Start,
            DATE_FORMAT(end_ts, '%H:%i') AS End,
            dp.place_name AS Location,
            d.department_name AS Department,
            dp.procedure_category AS Category,
            LEFT(dp.procedure_name, 72) AS Procedure_Name,
            CONCAT(dp.first_name, ' ', dp.last_name) AS Lead_Doctor,
            dp.actual_duration_min AS Minutes
        FROM doctor_procedure dp
        JOIN hospitalization h ON h.hosp_id = dp.hosp_id
        JOIN department d ON d.department_id = h.department_id
        WHERE DATE(dp.start_ts) = '{date_literal}' {dept_and}
        ORDER BY dp.start_ts
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
        WHERE DATE(ev.arrival_ts) = '{date_literal}' {dept_and}
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
        f"""
        SELECT 'Processing shifts' AS Monitor, COUNT(*) AS Open_Items
        FROM department_shift ds
        JOIN department d ON d.department_id = ds.department_id
        WHERE ds.shift_status = 'PROCESSING' {dept_and}
        UNION ALL
        SELECT 'Beds in maintenance' AS Monitor, COUNT(*) AS Open_Items
        FROM bed b
        JOIN department d ON d.department_id = b.department_id
        WHERE b.bed_status = 'MAINTENANCE' {dept_and}
        UNION ALL
        SELECT 'Open emergency queue' AS Monitor, COUNT(*) AS Open_Items
        FROM emergency_visit ev
        LEFT JOIN department d ON d.department_id = ev.referred_department_id
        WHERE ev.status = 'WAITING' {dept_and}
        UNION ALL
        SELECT 'Missing discharge diagnosis' AS Monitor, COUNT(*) AS Open_Items
        FROM hospitalization h
        JOIN department d ON d.department_id = h.department_id
        WHERE h.discharge_ts IS NOT NULL AND h.discharge_icd10_code IS NULL {dept_and};
        """,
        config,
    )

    triage_mix = load_dataframe(
        f"""
        SELECT
            ev.emergency_level AS Priority,
            COUNT(*) AS Visits,
            SUM(CASE WHEN ev.status = 'WAITING' THEN 1 ELSE 0 END) AS Waiting,
            SUM(CASE WHEN ev.status = 'CALLED' THEN 1 ELSE 0 END) AS Called
        FROM emergency_visit ev
        LEFT JOIN department d ON d.department_id = ev.referred_department_id
        WHERE DATE(ev.arrival_ts) = '{date_literal}' {dept_and}
        GROUP BY ev.emergency_level
        ORDER BY ev.emergency_level;
        """,
        config,
    )

    col_e, col_f = st.columns([0.62, 0.38])
    with col_e:
        render_table("Operational Monitors", monitors, height=210)
    with col_f:
        render_table("Emergency Triage Mix", triage_mix, height=210)


def render_patient_records(config: DbConfig) -> None:
    render_page_header("Patient Records", "Clinical Registry", "History | Prescriptions | Labs")

    search_text = st.text_input("Patient search", placeholder="AMKA, first name, or last name")
    search_clean = sql_text(search_text.strip())

    if search_clean:
        patients = load_dataframe(
            f"""
            SELECT
                p.patient_amka AS AMKA,
                CONCAT(p.first_name, ' ', p.last_name) AS Patient,
                p.age AS Age,
                p.gender AS Gender,
                p.insurance_provider AS Insurance,
                COUNT(h.hosp_id) AS Hospitalizations,
                MAX(h.admission_ts) AS Last_Admission
            FROM patient p
            LEFT JOIN hospitalization h ON h.patient_amka = p.patient_amka
            WHERE p.patient_amka LIKE '%{search_clean}%'
               OR p.first_name LIKE '%{search_clean}%'
               OR p.last_name LIKE '%{search_clean}%'
            GROUP BY p.patient_amka, p.first_name, p.last_name, p.age, p.gender, p.insurance_provider
            ORDER BY Last_Admission DESC, Patient
            LIMIT 25;
            """,
            config,
        )
    else:
        patients = load_dataframe(
            """
            SELECT
                p.patient_amka AS AMKA,
                CONCAT(p.first_name, ' ', p.last_name) AS Patient,
                p.age AS Age,
                p.gender AS Gender,
                p.insurance_provider AS Insurance,
                COUNT(h.hosp_id) AS Hospitalizations,
                MAX(h.admission_ts) AS Last_Admission
            FROM patient p
            JOIN hospitalization h ON h.patient_amka = p.patient_amka
            GROUP BY p.patient_amka, p.first_name, p.last_name, p.age, p.gender, p.insurance_provider
            ORDER BY Last_Admission DESC, Patient
            LIMIT 25;
            """,
            config,
        )

    if patients.empty:
        st.info("No patient records found.")
        return

    render_table("Patient Index", patients, height=260)
    patient_options = {
        f"{row.Patient} | {row.AMKA}": str(row.AMKA)
        for row in patients.itertuples(index=False)
    }
    selected_label = st.selectbox("Open record", list(patient_options.keys()))
    selected_amka = sql_text(patient_options[selected_label])

    summary = load_dataframe(
        f"""
        SELECT
            (SELECT COUNT(*) FROM hospitalization WHERE patient_amka = '{selected_amka}') AS hospitalizations,
            (SELECT COUNT(*) FROM prescription WHERE patient_amka = '{selected_amka}') AS prescriptions,
            (SELECT COUNT(*) FROM patient_allergy WHERE patient_amka = '{selected_amka}') AS allergies,
            (SELECT COALESCE(SUM(total_cost), 0) FROM hospitalization WHERE patient_amka = '{selected_amka}') AS total_cost;
        """,
        config,
    )
    summary_row = summary.iloc[0] if not summary.empty else pd.Series(dtype=object)

    m1, m2, m3, m4 = st.columns(4)
    m1.metric("Hospitalizations", metric_value(summary_row, "hospitalizations"))
    m2.metric("Prescriptions", metric_value(summary_row, "prescriptions"))
    m3.metric("Allergies", metric_value(summary_row, "allergies"))
    m4.metric("Total Cost", metric_value(summary_row, "total_cost"))

    history = load_dataframe(
        f"""
        SELECT
            hosp_id AS Hosp_ID,
            department_name AS Department,
            admission_ts AS Admission,
            discharge_ts AS Discharge,
            icd10_code AS ICD10,
            LEFT(icd10_description, 90) AS Diagnosis,
            ken_code AS KEN,
            total_cost AS Cost
        FROM patient_history
        WHERE patient_amka = '{selected_amka}'
        ORDER BY admission_ts DESC;
        """,
        config,
    )

    prescriptions = load_dataframe(
        f"""
        SELECT
            prescription_id AS Prescription_ID,
            drug_name AS Drug,
            substance_name AS Active_Substance,
            start_datetime AS Start,
            end_datetime AS End
        FROM prescription_substances
        WHERE patient_amka = '{selected_amka}'
        ORDER BY start_datetime DESC
        LIMIT 50;
        """,
        config,
    )

    allergies = load_dataframe(
        f"""
        SELECT a.substance_name AS Active_Substance
        FROM patient_allergy pa
        JOIN active_substance a ON a.substance_id = pa.substance_id
        WHERE pa.patient_amka = '{selected_amka}'
        ORDER BY a.substance_name;
        """,
        config,
    )

    labs = load_dataframe(
        f"""
        SELECT
            lt.test_datetime AS Test_Date,
            ltc.test_name AS Test,
            ltc.test_type AS Type,
            LEFT(COALESCE(lt.result_text, ''), 120) AS Result
        FROM lab_test lt
        JOIN lab_test_catalog ltc ON ltc.test_code = lt.test_code
        JOIN hospitalization h ON h.hosp_id = lt.hosp_id
        WHERE h.patient_amka = '{selected_amka}'
        ORDER BY lt.test_datetime DESC
        LIMIT 50;
        """,
        config,
    )

    left_col, right_col = st.columns([0.58, 0.42])
    with left_col:
        render_table("Hospitalization History", history, height=320)
        render_table("Lab Activity", labs, height=280)
    with right_col:
        render_table("Prescriptions", prescriptions, height=320)
        render_table("Allergy Profile", allergies, height=180)


def render_setup(config: DbConfig) -> None:
    render_page_header("Database Setup", "Administration", "Install | Load | Validate")

    col1, col2, col3 = st.columns(3)
    with col1:
        working_dir_text = st.text_input("Working directory", value=str(PROJECT_ROOT))
    with col2:
        install_script_text = st.text_input("Install script", value=str(SQL_DIR / "install.sql"))
    with col3:
        load_script_text = st.text_input("Load script", value=str(SQL_DIR / "load.sql"))

    validation_script_text = st.text_input("Validation script", value=str(SQL_DIR / "validation.sql"))

    st.warning("Install recreates `yg_eupolis_hospital`; load then imports all CSV data.")

    if st.button("Run install/load/validation", type="primary"):
        working_dir = Path(working_dir_text).expanduser()
        scripts = [
            ("install.sql", Path(install_script_text).expanduser()),
            ("load.sql", Path(load_script_text).expanduser()),
            ("validation.sql", Path(validation_script_text).expanduser()),
        ]

        if not working_dir.exists():
            st.error(f"Working directory does not exist: {working_dir}")
            return
        for label, script_path in scripts:
            if not script_path.exists():
                st.error(f"{label} does not exist: {script_path}")
                return

        results = []
        with st.spinner("Installing schema and loading data..."):
            for label, script_path in scripts:
                result = run_mysql_script(script_path, working_dir, config)
                results.append((label, result))
                if result.returncode != 0:
                    break

        if all(result.returncode == 0 for _, result in results):
            st.success("Database install/load/validation completed.")
        else:
            failed_label, failed_result = next((label, result) for label, result in results if result.returncode != 0)
            st.error(f"{failed_label} failed with exit code {failed_result.returncode}.")

        for label, result in results:
            if result.stdout:
                st.text_area(f"{label} output", result.stdout, height=220)
            if result.stderr:
                st.text_area(f"{label} errors", result.stderr, height=160)


def render_queries(config: DbConfig) -> None:
    render_page_header("SQL Workspace", "Reporting", "Q01-Q15")
    render_query_inventory()

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

    query_parameters = parse_query_parameters(sql_text)
    parameter_values: dict[str, dict[str, Any]] = {}
    if query_parameters:
        st.markdown('<div class="section-label">Query Parameters</div>', unsafe_allow_html=True)
        parameter_cols = st.columns(min(3, len(query_parameters)))
        for index, parameter in enumerate(query_parameters):
            variable = parameter["variable"]
            with parameter_cols[index % len(parameter_cols)]:
                value = st.text_input(
                    variable,
                    value=parameter["default_value"],
                    key=f"param_{query_file.name}_{variable}",
                    help="This value replaces the matching SET statement when the query runs.",
                )
            parameter_values[variable] = {
                "value": value,
                "quoted": parameter["quoted"],
            }

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
                sql_to_run = apply_query_parameters(sql_text, parameter_values)
                result = execute_sql(sql_to_run, config)
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
    module = st.session_state.get("module", "Operations")

    if module == "Operations":
        render_dashboard(config)
    elif module == "Patient Records":
        render_patient_records(config)
    elif module == "Database Setup":
        render_setup(config)
    else:
        render_queries(config)
