from __future__ import annotations

from datetime import date
from html import escape
import os
import re
from typing import Any

import pandas as pd
import streamlit as st

from queries import (
    DbConfig,
    SQL_DIR,
    detect_unix_socket,
    execute_readonly_script,
    fetch_dataframe,
    get_query_file,
    is_safe_predefined_script,
    query_files,
    read_query,
    save_query_output,
    test_connection,
)


PAGES = [
    "Executive Overview",
    "Patient Lookup",
    "Doctor & Procedure Analytics",
    "Shift Staffing Console",
    "Emergency Triage Monitor",
    "Medication & Allergy Safety",
    "Query Workspace",
    "Validation & Health Check",
]

SET_PARAMETER_PATTERN = re.compile(r"(?im)^\s*SET\s+(@[A-Za-z0-9_]+)\s*=\s*(.+?)\s*;\s*$")


def apply_theme() -> None:
    st.markdown(
        """
        <style>
        :root {
            --bg: #edf3fb;
            --bg-deep: #dbeafe;
            --panel: #f9fbff;
            --panel-soft: #edf6ff;
            --panel-blue: #e7f0ff;
            --text: #102033;
            --muted: #5f7087;
            --border: #c8d8ea;
            --brand: #1d4ed8;
            --brand-2: #0f766e;
            --nav: #0b1f3a;
            --nav-soft: #12345b;
            --ok: #15803d;
            --warn: #b7791f;
            --critical: #b91c1c;
            --shadow: 0 14px 36px rgba(15, 42, 82, 0.10);
        }
        .stApp {
            background:
                radial-gradient(circle at top left, rgba(29, 78, 216, 0.22), transparent 28rem),
                radial-gradient(circle at top right, rgba(15, 118, 110, 0.14), transparent 24rem),
                linear-gradient(180deg, #f4f8ff 0%, var(--bg) 46%, #eaf1fb 100%);
            color: var(--text);
        }
        .stApp::before {
            background-image: url("data:image/svg+xml,%3Csvg width='720' height='520' viewBox='0 0 720 520' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M360 54L522 112V246C522 351 451 442 360 474C269 442 198 351 198 246V112L360 54Z' stroke='%231d4ed8' stroke-width='20'/%3E%3Cpath d='M264 284H320L345 218L384 338L417 250H488' stroke='%230f766e' stroke-width='18' stroke-linecap='round' stroke-linejoin='round'/%3E%3Cpath d='M360 150V218M326 184H394' stroke='%231d4ed8' stroke-width='18' stroke-linecap='round'/%3E%3Ccircle cx='360' cy='260' r='202' stroke='%230ea5e9' stroke-width='4' stroke-dasharray='10 18'/%3E%3C/svg%3E");
            background-position: right 5vw top 12vh;
            background-repeat: no-repeat;
            background-size: min(54vw, 720px) auto;
            content: "";
            inset: 0;
            opacity: 0.075;
            pointer-events: none;
            position: fixed;
            z-index: 0;
        }
        .stApp > header,
        .stApp [data-testid="stAppViewContainer"],
        .stApp [data-testid="stSidebar"] {
            position: relative;
            z-index: 1;
        }
        .stApp [data-testid="stAppViewContainer"]::after {
            background:
                linear-gradient(90deg, rgba(29,78,216,0.08) 1px, transparent 1px),
                linear-gradient(180deg, rgba(29,78,216,0.08) 1px, transparent 1px);
            background-size: 44px 44px;
            content: "";
            inset: 0;
            opacity: 0.18;
            pointer-events: none;
            position: fixed;
            z-index: -1;
        }
        [data-testid="stSidebar"] {
            background:
                linear-gradient(180deg, var(--nav) 0%, #0e2747 48%, #0f314f 100%);
            border-right: 1px solid rgba(255,255,255,0.08);
        }
        [data-testid="stSidebar"] [data-testid="stSidebarContent"] {
            padding-top: 1.1rem;
        }
        [data-testid="stSidebar"] label,
        [data-testid="stSidebar"] p,
        [data-testid="stSidebar"] span {
            color: rgba(255,255,255,0.78);
        }
        [data-testid="stSidebar"] input {
            background: rgba(255,255,255,0.08);
            border-color: rgba(255,255,255,0.16);
            color: #ffffff;
        }
        [data-testid="stSidebar"] div[role="radiogroup"] label {
            background: rgba(255,255,255,0.04);
            border: 1px solid transparent;
            border-radius: 8px;
            margin: 0.12rem 0;
            padding: 0.35rem 0.45rem;
        }
        [data-testid="stSidebar"] div[role="radiogroup"] label:hover {
            background: rgba(255,255,255,0.08);
            border-color: rgba(255,255,255,0.14);
        }
        h1, h2, h3 { color: var(--text); letter-spacing: 0; }
        h1 { font-size: 1.65rem; margin: 0; }
        h2 { font-size: 1.16rem; margin-top: 1.2rem; }
        .topbar {
            align-items: center;
            background:
                linear-gradient(135deg, rgba(255,255,255,0.96), rgba(232,241,255,0.92));
            border: 1px solid rgba(79, 116, 166, 0.22);
            border-left: 5px solid var(--brand);
            border-radius: 12px;
            box-shadow: 0 18px 42px rgba(16, 45, 88, 0.10);
            display: flex;
            justify-content: space-between;
            margin-bottom: 1rem;
            padding: 0.95rem 1.05rem;
        }
        .eyebrow {
            color: #1d4ed8;
            font-size: 0.72rem;
            font-weight: 800;
            letter-spacing: 0.08em;
            text-transform: uppercase;
        }
        .meta {
            color: var(--muted);
            font-size: 0.82rem;
            text-align: right;
        }
        .kpi {
            background:
                linear-gradient(180deg, rgba(255,255,255,0.98), rgba(238,246,255,0.96));
            border: 1px solid rgba(96, 132, 180, 0.22);
            border-top: 3px solid rgba(29, 78, 216, 0.72);
            border-radius: 12px;
            box-shadow: 0 14px 34px rgba(20, 54, 105, 0.09);
            min-height: 92px;
            padding: 0.85rem 0.95rem;
        }
        .kpi-label {
            color: var(--muted);
            font-size: 0.76rem;
            font-weight: 700;
            text-transform: uppercase;
        }
        .kpi-value {
            color: var(--text);
            font-size: 1.55rem;
            font-weight: 800;
            line-height: 1.25;
            margin-top: 0.35rem;
        }
        .kpi-note {
            color: var(--muted);
            font-size: 0.76rem;
            margin-top: 0.25rem;
        }
        .badge {
            border-radius: 999px;
            display: inline-block;
            font-size: 0.72rem;
            font-weight: 800;
            padding: 0.18rem 0.55rem;
        }
        .badge-ok { background: #d8f5e4; color: var(--ok); }
        .badge-warn { background: #fff1c2; color: var(--warn); }
        .badge-critical { background: #fee2e2; color: var(--critical); }
        .section-label {
            color: var(--muted);
            font-size: 0.76rem;
            font-weight: 800;
            letter-spacing: 0.06em;
            margin: 0.9rem 0 0.45rem;
            text-transform: uppercase;
        }
        .empty {
            background: var(--panel-soft);
            border: 1px dashed var(--border);
            border-radius: 10px;
            color: var(--muted);
            padding: 1rem;
        }
        .brand {
            background:
                linear-gradient(135deg, rgba(37, 99, 235, 0.94), rgba(20, 184, 166, 0.78));
            border: 1px solid rgba(255,255,255,0.20);
            border-radius: 12px;
            box-shadow: 0 16px 30px rgba(0,0,0,0.16);
            color: white;
            margin-bottom: 0.9rem;
            padding: 0.9rem;
        }
        .brand strong { display: block; font-size: 1rem; }
        .brand span { color: rgba(255,255,255,0.78); font-size: 0.78rem; }
        .side-title {
            color: rgba(191, 219, 254, 0.92);
            font-size: 0.72rem;
            font-weight: 800;
            letter-spacing: 0.07em;
            margin: 1rem 0 0.35rem;
            text-transform: uppercase;
        }
        div[data-testid="stMetric"],
        div[data-testid="stDataFrame"] {
            background: rgba(249, 251, 255, 0.96);
            border: 1px solid rgba(96, 132, 180, 0.24);
            border-radius: 12px;
            box-shadow: 0 10px 28px rgba(20, 54, 105, 0.06);
            overflow: hidden;
        }
        [data-testid="stSelectbox"] div[data-baseweb="select"],
        [data-testid="stTextInput"] input,
        [data-testid="stNumberInput"] input,
        [data-testid="stDateInput"] input {
            border-color: rgba(96, 132, 180, 0.32);
        }
        .stButton > button {
            border-radius: 7px;
            border: 1px solid var(--border);
            font-weight: 700;
        }
        .stButton > button[kind="primary"] {
            background: linear-gradient(135deg, var(--brand), #0f766e);
            border-color: transparent;
            box-shadow: 0 10px 22px rgba(29, 78, 216, 0.20);
        }
        code { white-space: pre-wrap; }
        </style>
        """,
        unsafe_allow_html=True,
    )


def secret_value(name: str, default: str = "") -> str:
    try:
        return str(st.secrets.get(name, os.getenv(name, default)))
    except Exception:
        return os.getenv(name, default)


def db_config_from_sidebar() -> DbConfig:
    detected_socket = detect_unix_socket()
    with st.sidebar:
        st.markdown(
            '<div class="brand"><strong>Ygeiopolis HIS</strong><span>Hospital operations console</span></div>',
            unsafe_allow_html=True,
        )
        st.markdown('<div class="side-title">Role</div>', unsafe_allow_html=True)
        role = st.selectbox("Role", ["Viewer", "Analyst", "Admin"], label_visibility="collapsed")
        st.session_state["role"] = role

        st.markdown('<div class="side-title">Navigation</div>', unsafe_allow_html=True)
        page = st.radio("Page", PAGES, label_visibility="collapsed")
        st.session_state["page"] = page

        st.markdown('<div class="side-title">Database</div>', unsafe_allow_html=True)
        with st.expander("Connection", expanded=False):
            host = st.text_input("Host", value=secret_value("DB_HOST", "localhost"))
            port = st.number_input("Port", value=int(secret_value("DB_PORT", "3306")), min_value=1, max_value=65535)
            user = st.text_input("User", value=secret_value("DB_USER", "root"))
            password = st.text_input("Password", value=secret_value("DB_PASSWORD", ""), type="password")
            database = st.text_input("Database", value=secret_value("DB_NAME", "yg_eupolis_hospital"))
            socket_default = secret_value("DB_SOCKET", detected_socket)
            unix_socket = st.text_input("Unix socket", value=socket_default)

        config = DbConfig(
            host=host.strip() or "localhost",
            port=int(port),
            user=user.strip() or "root",
            password=password,
            database=database.strip() or "yg_eupolis_hospital",
            unix_socket=unix_socket.strip(),
        )

        status = connection_status(config)
        if status:
            st.markdown(status, unsafe_allow_html=True)
        if st.button("Test connection", width="stretch"):
            try:
                test_connection(config)
                st.success("Connection is healthy.")
                add_audit("Connection test succeeded")
            except Exception:
                st.error("Could not connect. Check MySQL is running and credentials are correct.")
                add_audit("Connection test failed")

        render_audit_panel()
    return config


def add_audit(message: str) -> None:
    events = st.session_state.setdefault("audit_events", [])
    if not events or events[-1] != message:
        events.append(message)
    st.session_state["audit_events"] = events[-6:]


def render_audit_panel() -> None:
    events = st.session_state.get("audit_events", [])
    st.markdown('<div class="side-title">Session Activity</div>', unsafe_allow_html=True)
    if not events:
        st.caption("No UI actions recorded yet.")
        return
    for event in reversed(events[-4:]):
        st.caption(event)


def safe_df(sql: str, config: DbConfig, params: tuple[Any, ...] = ()) -> pd.DataFrame:
    return fetch_dataframe(sql, config, params)


def try_df(sql: str, config: DbConfig, params: tuple[Any, ...] = ()) -> pd.DataFrame:
    try:
        return safe_df(sql, config, params)
    except Exception:
        return pd.DataFrame()


def connection_status(config: DbConfig) -> str:
    try:
        counts = safe_df(
            """
            SELECT
                (SELECT COUNT(*) FROM patient) AS patients,
                (SELECT COUNT(*) FROM hospitalization) AS hospitalizations,
                (SELECT COUNT(*) FROM prescription) AS prescriptions
            """,
            config,
        )
        if counts.empty:
            return '<span class="badge badge-warn">Database not loaded</span>'
        row = counts.iloc[0]
        return (
            '<span class="badge badge-ok">Database online</span><br>'
            f'<span style="color:#64748b;font-size:0.78rem;">'
            f'{int(row.patients):,} patients | {int(row.hospitalizations):,} hospitalizations | '
            f'{int(row.prescriptions):,} prescriptions</span>'
        )
    except Exception:
        return '<span class="badge badge-critical">Database offline</span>'


def page_header(title: str, section: str, meta: str = "") -> None:
    st.markdown(
        f"""
        <div class="topbar">
            <div>
                <div class="eyebrow">{escape(section)}</div>
                <h1>{escape(title)}</h1>
            </div>
            <div class="meta">{escape(meta)}</div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def kpi(label: str, value: Any, note: str = "", status: str = "ok") -> None:
    badge_class = {"ok": "badge-ok", "warn": "badge-warn", "critical": "badge-critical"}.get(status, "badge-ok")
    value_text = "0" if value is None or (isinstance(value, float) and pd.isna(value)) else str(value)
    st.markdown(
        f"""
        <div class="kpi">
            <div class="kpi-label">{escape(label)}</div>
            <div class="kpi-value">{escape(value_text)}</div>
            <div class="kpi-note"><span class="badge {badge_class}">{escape(note or "Current")}</span></div>
        </div>
        """,
        unsafe_allow_html=True,
    )


def fmt(value: Any) -> str:
    if value is None or pd.isna(value):
        return "0"
    if isinstance(value, (int, float)):
        return f"{value:,.0f}" if float(value).is_integer() else f"{value:,.1f}"
    return str(value)


def section(label: str) -> None:
    st.markdown(f'<div class="section-label">{escape(label)}</div>', unsafe_allow_html=True)


def data_table(label: str, dataframe: pd.DataFrame, height: int = 300) -> None:
    section(label)
    if dataframe.empty:
        st.markdown('<div class="empty">No records for the selected filters.</div>', unsafe_allow_html=True)
        return
    st.dataframe(dataframe, width="stretch", height=height, hide_index=True)
    st.download_button(
        "Export CSV",
        dataframe.to_csv(index=False).encode("utf-8"),
        file_name=f"{label.lower().replace(' ', '_')}.csv",
        mime="text/csv",
        key=f"export_{re.sub(r'[^a-z0-9]+', '_', label.lower()).strip('_')}_{height}",
        width="stretch",
    )


def departments(config: DbConfig) -> list[str]:
    df = try_df("SELECT department_name FROM department ORDER BY department_name", config)
    return [str(v) for v in df["department_name"].tolist()] if not df.empty else []


def specialties(config: DbConfig) -> list[str]:
    df = try_df("SELECT DISTINCT specialization FROM doctor ORDER BY specialization", config)
    return [str(v) for v in df["specialization"].tolist()] if not df.empty else []


def ranks(config: DbConfig) -> list[str]:
    df = try_df("SELECT DISTINCT doctor_rank FROM doctor ORDER BY doctor_rank", config)
    return [str(v) for v in df["doctor_rank"].tolist()] if not df.empty else []


def render_exec_overview(config: DbConfig) -> None:
    page_header("Executive Overview", "Hospital Operations", "Read-only operational snapshot")
    try:
        summary = safe_df(
            """
            SELECT
                (SELECT COUNT(*) FROM patient) AS patients,
                (SELECT COUNT(*) FROM hospitalization) AS hospitalizations,
                (SELECT COUNT(*) FROM doctor) AS doctors,
                (SELECT COUNT(*) FROM nurse) AS nurses,
                (SELECT COUNT(*) FROM department) AS departments,
                (SELECT COUNT(*) FROM emergency_visit) AS emergency_visits,
                (SELECT COUNT(*) FROM procedure_event) AS procedure_events,
                (SELECT COUNT(*) FROM prescription) AS prescriptions,
                (SELECT COUNT(*) FROM department_shift WHERE shift_status <> 'VALID') AS open_shift_checks
            """,
            config,
        )
    except Exception:
        st.error("The database is not reachable or has not been loaded yet.")
        return

    row = summary.iloc[0]
    cols = st.columns(4)
    with cols[0]: kpi("Patients", fmt(row.patients), "Registry")
    with cols[1]: kpi("Hospitalizations", fmt(row.hospitalizations), "Clinical")
    with cols[2]: kpi("Doctors / Nurses", f"{fmt(row.doctors)} / {fmt(row.nurses)}", "Staff")
    with cols[3]: kpi("Prescriptions", fmt(row.prescriptions), "Medication")
    cols = st.columns(4)
    with cols[0]: kpi("Departments", fmt(row.departments), "Structure")
    with cols[1]: kpi("Emergency Visits", fmt(row.emergency_visits), "ED")
    with cols[2]: kpi("Procedures", fmt(row.procedure_events), "OR")
    with cols[3]: kpi("Validation", "PASS" if row.open_shift_checks == 0 else "CHECK", "No open shifts" if row.open_shift_checks == 0 else "Review shifts", "ok" if row.open_shift_checks == 0 else "warn")

    col_a, col_b = st.columns([1.15, 0.85])
    with col_a:
        hosp_by_dept = try_df(
            """
            SELECT d.department_name AS Department, COUNT(h.hosp_id) AS Hospitalizations
            FROM department d
            LEFT JOIN hospitalization h ON h.department_id = d.department_id
            GROUP BY d.department_name
            ORDER BY Hospitalizations DESC
            """,
            config,
        )
        data_table("Hospitalizations by Department", hosp_by_dept, 330)
    with col_b:
        triage = try_df(
            """
            SELECT emergency_level AS Triage_Level, COUNT(*) AS Visits
            FROM emergency_visit
            GROUP BY emergency_level
            ORDER BY emergency_level
            """,
            config,
        )
        section("Emergency Visits by Triage Level")
        if not triage.empty:
            st.bar_chart(triage.set_index("Triage_Level"), height=260)
        else:
            st.info("No triage data available.")

    col_c, col_d = st.columns(2)
    with col_c:
        revenue = try_df(
            """
            SELECT d.department_name AS Department,
                   YEAR(h.admission_ts) AS Year,
                   ROUND(SUM(h.total_cost), 2) AS Revenue
            FROM hospitalization h
            JOIN department d ON d.department_id = h.department_id
            GROUP BY d.department_name, YEAR(h.admission_ts)
            ORDER BY Year DESC, Revenue DESC
            LIMIT 25
            """,
            config,
        )
        data_table("Revenue by Department and Year", revenue, 300)
    with col_d:
        recent = try_df(
            """
            SELECT CONCAT(p.first_name, ' ', p.last_name) AS Patient,
                   d.department_name AS Department,
                   h.admission_ts AS Admission,
                   h.discharge_ts AS Discharge,
                   h.total_cost AS Cost
            FROM hospitalization h
            JOIN patient p ON p.patient_amka = h.patient_amka
            JOIN department d ON d.department_id = h.department_id
            ORDER BY h.admission_ts DESC
            LIMIT 20
            """,
            config,
        )
        data_table("Recent Admissions and Discharges", recent, 300)


def render_patient_lookup(config: DbConfig) -> None:
    page_header("Patient Lookup", "Clinical Registry", "Profile, history, diagnoses, prescriptions")
    term = st.text_input("Search patient", placeholder="AMKA, first name, or last name")
    like = f"%{term.strip()}%"
    patients = try_df(
        """
        SELECT p.patient_amka AS AMKA,
               CONCAT(p.first_name, ' ', p.last_name) AS Patient,
               p.age AS Age,
               p.gender AS Gender,
               p.insurance_provider AS Insurance,
               COUNT(h.hosp_id) AS Hospitalizations,
               MAX(h.admission_ts) AS Last_Admission
        FROM patient p
        LEFT JOIN hospitalization h ON h.patient_amka = p.patient_amka
        WHERE (%s = '%%' OR p.patient_amka LIKE %s OR p.first_name LIKE %s OR p.last_name LIKE %s)
        GROUP BY p.patient_amka, p.first_name, p.last_name, p.age, p.gender, p.insurance_provider
        ORDER BY Last_Admission DESC
        LIMIT 30
        """,
        config,
        (like, like, like, like),
    )
    data_table("Patient Index", patients, 260)
    if patients.empty:
        return
    options = {f"{r.Patient} | {r.AMKA}": r.AMKA for r in patients.itertuples(index=False)}
    selected = st.selectbox("Selected patient", list(options.keys()))
    amka = str(options[selected])

    stats = try_df(
        """
        SELECT
            (SELECT COUNT(*) FROM hospitalization WHERE patient_amka = %s) AS hospitalizations,
            (SELECT COUNT(*) FROM prescription WHERE patient_amka = %s) AS prescriptions,
            (SELECT COUNT(*) FROM patient_allergy WHERE patient_amka = %s) AS allergies,
            (SELECT ROUND(COALESCE(SUM(total_cost), 0), 2) FROM hospitalization WHERE patient_amka = %s) AS total_cost
        """,
        config,
        (amka, amka, amka, amka),
    )
    if not stats.empty:
        s = stats.iloc[0]
        cols = st.columns(4)
        with cols[0]: kpi("Hospitalizations", fmt(s.hospitalizations), "Patient")
        with cols[1]: kpi("Prescriptions", fmt(s.prescriptions), "Medication")
        with cols[2]: kpi("Allergies", fmt(s.allergies), "Safety", "warn" if s.allergies else "ok")
        with cols[3]: kpi("Total Cost", fmt(s.total_cost), "KEN")

    col_a, col_b = st.columns([1.1, 0.9])
    with col_a:
        history = try_df(
            """
            SELECT department_name AS Department,
                   admission_ts AS Admission,
                   discharge_ts AS Discharge,
                   icd10_code AS ICD10,
                   LEFT(icd10_description, 90) AS Diagnosis,
                   ken_code AS KEN,
                   total_cost AS Cost
            FROM patient_history
            WHERE patient_amka = %s
            ORDER BY admission_ts DESC
            """,
            config,
            (amka,),
        )
        data_table("Hospitalization History", history, 340)
    with col_b:
        prescriptions = try_df(
            """
            SELECT drug_name AS Drug,
                   substance_name AS Active_Substance,
                   start_datetime AS Start,
                   end_datetime AS End
            FROM prescription_substances
            WHERE patient_amka = %s
            ORDER BY start_datetime DESC
            LIMIT 80
            """,
            config,
            (amka,),
        )
        data_table("Prescriptions", prescriptions, 340)

    col_c, col_d = st.columns(2)
    with col_c:
        evals = try_df(
            """
            SELECT he.evaluation_date AS Evaluation_Date,
                   he.medical_care_score AS Medical,
                   he.nursing_care_score AS Nursing,
                   he.cleanliness_score AS Cleanliness,
                   he.food_score AS Food,
                   he.overall_experience_score AS Overall,
                   he.comments AS Comments
            FROM hospitalization_evaluation he
            JOIN hospitalization h ON h.hosp_id = he.hosp_id
            WHERE h.patient_amka = %s
            ORDER BY he.evaluation_date DESC
            """,
            config,
            (amka,),
        )
        data_table("Evaluations", evals, 260)
    with col_d:
        allergies = try_df(
            """
            SELECT a.substance_name AS Active_Substance
            FROM patient_allergy pa
            JOIN active_substance a ON a.substance_id = pa.substance_id
            WHERE pa.patient_amka = %s
            ORDER BY a.substance_name
            """,
            config,
            (amka,),
        )
        data_table("Allergy Profile", allergies, 260)


def render_doctor_analytics(config: DbConfig) -> None:
    page_header("Doctor & Procedure Analytics", "Clinical Operations", "Surgeons, specialties, volumes")
    col1, col2, col3 = st.columns(3)
    specialty = col1.selectbox("Specialty", ["All specialties"] + specialties(config))
    rank = col2.selectbox("Rank", ["All ranks"] + ranks(config))
    year = col3.selectbox("Procedure year", ["All years"] + [str(y) for y in range(2026, 2023, -1)])
    filters = []
    params: list[Any] = []
    if specialty != "All specialties":
        filters.append("specialization = %s")
        params.append(specialty)
    if rank != "All ranks":
        filters.append("doctor_rank = %s")
        params.append(rank)
    if year != "All years":
        filters.append("procedure_year = %s")
        params.append(int(year))
    where = ("WHERE " + " AND ".join(filters)) if filters else ""

    top = try_df(
        f"""
        SELECT doctor_name AS Doctor,
               specialization AS Specialty,
               doctor_rank AS Rank,
               COUNT(DISTINCT procedure_event_id) AS Procedures,
               ROUND(AVG(actual_duration_min), 1) AS Avg_Minutes,
               MIN(start_ts) AS First_Procedure,
               MAX(start_ts) AS Last_Procedure
        FROM v_doctor_procedure_event
        {where}
        GROUP BY doctor_amka, doctor_name, specialization, doctor_rank
        ORDER BY Procedures DESC, Avg_Minutes DESC
        LIMIT 25
        """,
        config,
        tuple(params),
    )
    data_table("Top Surgeons", top, 330)

    col_a, col_b = st.columns(2)
    with col_a:
        yearly = try_df(
            f"""
            SELECT procedure_year AS Year, procedure_category AS Category, COUNT(*) AS Procedures
            FROM v_doctor_procedure_event
            {where}
            GROUP BY procedure_year, procedure_category
            ORDER BY Year, Category
            """,
            config,
            tuple(params),
        )
        data_table("Procedure Counts by Year and Category", yearly, 280)
    with col_b:
        young = try_df(
            f"""
            SELECT doctor_name AS Doctor, doctor_age AS Age, specialization AS Specialty,
                   COUNT(*) AS Surgical_Procedures
            FROM v_doctor_procedure_event
            {where + (' AND' if where else 'WHERE')} doctor_age < 35 AND procedure_category = 'SURGICAL'
            GROUP BY doctor_amka, doctor_name, doctor_age, specialization
            ORDER BY Surgical_Procedures DESC
            LIMIT 20
            """,
            config,
            tuple(params),
        )
        data_table("Young Doctors with Surgical Procedures", young, 280)


def render_shift_console(config: DbConfig) -> None:
    page_header("Shift Staffing Console", "Workforce", "Read-only roster monitoring")
    col1, col2, col3 = st.columns(3)
    depts = ["All departments"] + departments(config)
    dept = col1.selectbox("Department", depts)
    shift_date = col2.date_input("Shift date", value=date(2026, 3, 10))
    shift_type = col3.selectbox("Shift", ["All shifts", "MORNING", "AFTERNOON", "NIGHT"])
    filters = ["shift_date = %s"]
    params: list[Any] = [str(shift_date)]
    if dept != "All departments":
        filters.append("department_name = %s")
        params.append(dept)
    if shift_type != "All shifts":
        filters.append("shift_type = %s")
        params.append(shift_type)
    where = "WHERE " + " AND ".join(filters)

    coverage = try_df(
        f"""
        SELECT department_name AS Department, shift_type AS Shift, shift_status AS Status,
               COUNT(*) AS Staff,
               SUM(personnel_type = 'DOCTOR') AS Doctors,
               SUM(personnel_type = 'NURSE') AS Nurses,
               SUM(personnel_type = 'ADMIN') AS Administrative,
               SUM(assigned_role = 'SUPERVISOR') AS Supervisors
        FROM v_shift_staff
        {where}
        GROUP BY department_name, shift_type, shift_status
        ORDER BY Department, FIELD(Shift, 'MORNING', 'AFTERNOON', 'NIGHT')
        """,
        config,
        tuple(params),
    )
    data_table("Shift Coverage", coverage, 300)

    warnings = try_df(
        f"""
        SELECT department_name AS Department, shift_type AS Shift,
               CASE
                   WHEN SUM(personnel_type='DOCTOR') < 3 THEN 'Doctor coverage below expected'
                   WHEN SUM(personnel_type='NURSE') < 6 THEN 'Nurse coverage below expected'
                   WHEN SUM(assigned_role='RESIDENT') > 0 AND SUM(assigned_role='SUPERVISOR') = 0 THEN 'Resident without supervisor'
                   ELSE 'OK'
               END AS Finding
        FROM v_shift_staff
        {where}
        GROUP BY department_name, shift_type
        HAVING Finding <> 'OK'
        ORDER BY Department, Shift
        """,
        config,
        tuple(params),
    )
    if warnings.empty:
        st.success("No staffing warnings for the selected shift scope.")
    else:
        data_table("Staffing Warnings", warnings, 220)

    monthly = try_df(
        """
        SELECT personnel_name AS Staff_Member,
               personnel_type AS Staff_Type,
               DATE_FORMAT(shift_date, '%Y-%m') AS Month,
               COUNT(*) AS Shifts
        FROM v_shift_staff
        GROUP BY personnel_amka, personnel_name, personnel_type, DATE_FORMAT(shift_date, '%Y-%m')
        ORDER BY Shifts DESC
        LIMIT 40
        """,
        config,
    )
    data_table("Monthly Shift Counts per Staff Member", monthly, 320)


def render_emergency_monitor(config: DbConfig) -> None:
    page_header("Emergency Triage Monitor", "Emergency Department", "Priority queue and outcomes")
    metrics = try_df(
        """
        SELECT emergency_level AS Level,
               COUNT(*) AS Visits,
               ROUND(AVG(TIMESTAMPDIFF(MINUTE, arrival_ts, service_start_ts)), 1) AS Avg_Wait_Min,
               ROUND(100 * SUM(disposition='HOSPITALIZED') / COUNT(*), 1) AS Hospitalization_Rate
        FROM emergency_visit
        WHERE service_start_ts IS NOT NULL
        GROUP BY emergency_level
        ORDER BY emergency_level
        """,
        config,
    )
    data_table("Triage Performance", metrics, 260)

    col_a, col_b = st.columns(2)
    with col_a:
        referred = try_df(
            """
            SELECT COALESCE(d.department_name, 'Not referred') AS Department,
                   COUNT(*) AS Visits
            FROM emergency_visit ev
            LEFT JOIN department d ON d.department_id = ev.referred_department_id
            GROUP BY COALESCE(d.department_name, 'Not referred')
            ORDER BY Visits DESC
            LIMIT 20
            """,
            config,
        )
        data_table("Referred Departments", referred, 300)
    with col_b:
        queue = try_df(
            """
            SELECT ev.emergency_level AS Priority,
                   ev.arrival_ts AS Arrival,
                   ev.status AS Status,
                   CONCAT(p.first_name, ' ', p.last_name) AS Patient,
                   COALESCE(d.department_name, 'Not referred') AS Department
            FROM emergency_visit ev
            JOIN patient p ON p.patient_amka = ev.patient_amka
            LEFT JOIN department d ON d.department_id = ev.referred_department_id
            ORDER BY ev.emergency_level ASC, ev.arrival_ts ASC
            LIMIT 50
            """,
            config,
        )
        data_table("FIFO Queue View", queue, 300)


def render_medication_safety(config: DbConfig) -> None:
    page_header("Medication & Allergy Safety", "Medication Safety", "Official EMA references and trigger-backed checks")
    counts = try_df(
        """
        SELECT
            (SELECT COUNT(*) FROM drug) AS drugs,
            (SELECT COUNT(*) FROM active_substance) AS substances,
            (SELECT COUNT(*) FROM patient_allergy) AS allergies,
            (SELECT COUNT(*) FROM prescription) AS prescriptions
        """,
        config,
    )
    if not counts.empty:
        r = counts.iloc[0]
        cols = st.columns(4)
        with cols[0]: kpi("Drugs", fmt(r.drugs), "EMA")
        with cols[1]: kpi("Substances", fmt(r.substances), "EMA")
        with cols[2]: kpi("Allergies", fmt(r.allergies), "Patients")
        with cols[3]: kpi("Prescriptions", fmt(r.prescriptions), "Clinical")

    col_a, col_b = st.columns(2)
    with col_a:
        drug_search = st.text_input("Drug search", placeholder="Search drug name")
        drugs = try_df(
            """
            SELECT d.drug_name AS Drug,
                   GROUP_CONCAT(a.substance_name ORDER BY a.substance_name SEPARATOR ', ') AS Active_Substances
            FROM drug d
            JOIN drug_active_substance das ON das.drug_id = d.drug_id
            JOIN active_substance a ON a.substance_id = das.substance_id
            WHERE (%s = '' OR d.drug_name LIKE %s)
            GROUP BY d.drug_id, d.drug_name
            ORDER BY d.drug_name
            LIMIT 50
            """,
            config,
            (drug_search.strip(), f"%{drug_search.strip()}%"),
        )
        data_table("Active Substances per Drug", drugs, 340)
    with col_b:
        conflicts = try_df(
            """
            SELECT p.prescription_id AS Prescription,
                   p.patient_amka AS Patient_AMKA,
                   d.drug_name AS Drug,
                   a.substance_name AS Conflicting_Substance
            FROM prescription p
            JOIN drug d ON d.drug_id = p.drug_id
            JOIN drug_active_substance das ON das.drug_id = p.drug_id
            JOIN patient_allergy pa ON pa.patient_amka = p.patient_amka AND pa.substance_id = das.substance_id
            JOIN active_substance a ON a.substance_id = pa.substance_id
            LIMIT 50
            """,
            config,
        )
        if conflicts.empty:
            st.success("No prescription-allergy conflicts detected.")
        else:
            data_table("Allergy Conflict Checks", conflicts, 340)

    col_c, col_d = st.columns(2)
    with col_c:
        top_allergies = try_df(
            """
            SELECT a.substance_name AS Active_Substance, COUNT(*) AS Allergy_Count
            FROM patient_allergy pa
            JOIN active_substance a ON a.substance_id = pa.substance_id
            GROUP BY a.substance_name
            ORDER BY Allergy_Count DESC
            LIMIT 20
            """,
            config,
        )
        data_table("Top Active Substances by Allergy Count", top_allergies, 280)
    with col_d:
        q10 = get_query_file("Q10.sql")
        sql = read_query(q10)
        pairs = pd.DataFrame()
        try:
            if is_safe_predefined_script(sql):
                results = execute_readonly_script(sql, config)
                pairs = next((r.dataframe for r in reversed(results) if r.dataframe is not None), pd.DataFrame())
        except Exception:
            pairs = pd.DataFrame()
        data_table("Top Co-Prescribed Substance Pairs", pairs, 280)


def parse_query_parameters(sql: str) -> list[dict[str, Any]]:
    params = []
    seen = set()
    for match in SET_PARAMETER_PATTERN.finditer(sql):
        variable = match.group(1)
        if variable in seen:
            continue
        raw = match.group(2).strip()
        quoted = raw.startswith("'") and raw.endswith("'")
        default = raw[1:-1].replace("''", "'") if quoted else raw
        params.append({"variable": variable, "default": default, "quoted": quoted})
        seen.add(variable)
    return params


def apply_query_parameters(sql: str, values: dict[str, dict[str, Any]]) -> str:
    def replace(match: re.Match[str]) -> str:
        variable = match.group(1)
        value = values.get(variable)
        if not value:
            return match.group(0)
        raw = str(value["value"]).strip()
        escaped = raw.replace("'", "''")
        formatted = f"'{escaped}'" if value["quoted"] else raw or "NULL"
        return f"SET {variable} = {formatted};"

    return SET_PARAMETER_PATTERN.sub(replace, sql)


def query_inventory() -> pd.DataFrame:
    rows = []
    for q in query_files():
        sql = read_query(q).strip()
        ready = bool(sql) and not sql.startswith("-- TODO") and is_safe_predefined_script(sql)
        out = q.output_path.read_text(encoding="utf-8").strip() if q.output_path.exists() else ""
        rows.append({"Query": q.name, "Status": "Ready" if ready else "TODO", "Output": "Saved" if out and not out.startswith("TODO:") else "Pending"})
    return pd.DataFrame(rows)


def render_query_workspace(config: DbConfig) -> None:
    page_header("Query Workspace", "Assignment Queries", "Predefined Q01-Q15 only")
    role = st.session_state.get("role", "Viewer")
    inventory = query_inventory()
    data_table("Query Inventory", inventory, 230)
    selected = st.selectbox("Predefined query", inventory["Query"].tolist())
    q = get_query_file(selected)
    sql = read_query(q)
    st.code(sql or "-- Empty query file", language="sql")

    values: dict[str, dict[str, Any]] = {}
    params = parse_query_parameters(sql)
    if params:
        section("Query Parameters")
        cols = st.columns(min(3, len(params)))
        for idx, param in enumerate(params):
            with cols[idx % len(cols)]:
                values[param["variable"]] = {
                    "value": st.text_input(param["variable"], value=param["default"]),
                    "quoted": param["quoted"],
                }

    if not sql.strip() or sql.strip().startswith("-- TODO"):
        st.info("This query file is still a TODO.")
        return
    if not is_safe_predefined_script(sql):
        st.error("This query contains non-read-only SQL and cannot be run from the workspace.")
        return

    if st.button("Run predefined query", type="primary"):
        try:
            with st.spinner("Running query..."):
                prepared = apply_query_parameters(sql, values)
                results = execute_readonly_script(prepared, config)
            last = next((r for r in reversed(results) if r.dataframe is not None), None)
            if last and last.dataframe is not None:
                st.session_state[f"query_result_{selected}"] = last
                add_audit(f"Ran {selected}")
                st.success(last.message)
            else:
                st.info("Query executed but returned no table result.")
        except Exception:
            st.error("The query could not be executed safely. Check that the database is loaded.")

    result = st.session_state.get(f"query_result_{selected}")
    if result and result.dataframe is not None:
        data_table("Query Result", result.dataframe, 420)
        if role in {"Analyst", "Admin"}:
            if st.button("Save output to Qxx_out.txt"):
                save_query_output(q, result)
                add_audit(f"Saved output for {selected}")
                st.success("Output saved.")
        else:
            st.caption("Output saving is available to Analyst and Admin roles.")


def render_validation(config: DbConfig) -> None:
    page_header("Validation & Health Check", "Database Quality", "Counts and zero-row checks")
    validation_file = SQL_DIR / "validation.sql"
    sql = validation_file.read_text(encoding="utf-8") if validation_file.exists() else ""
    if not sql:
        st.error("Validation script is missing.")
        return
    try:
        with st.spinner("Running validation checks..."):
            results = execute_readonly_script(sql, config)
    except Exception:
        st.error("Validation could not run. Confirm the database is installed and loaded.")
        return

    if not results:
        st.warning("Validation returned no result sets.")
        return
    counts = results[0].dataframe if results[0].dataframe is not None else pd.DataFrame()
    data_table("Row Counts", counts, 420)
    problems = [r.dataframe for r in results[1:] if r.dataframe is not None and not r.dataframe.empty]
    if not problems:
        st.success("Validation passed. Problem-detection queries returned zero rows.")
        return
    st.error(f"Validation found {len(problems)} non-empty problem result set(s).")
    for idx, problem in enumerate(problems, 1):
        data_table(f"Validation Finding {idx}", problem, 260)


def render_app() -> None:
    st.set_page_config(page_title="Ygeiopolis HIS", layout="wide")
    apply_theme()
    config = db_config_from_sidebar()
    page = st.session_state.get("page", PAGES[0])
    add_audit(f"Opened {page}")

    if page == "Executive Overview":
        render_exec_overview(config)
    elif page == "Patient Lookup":
        render_patient_lookup(config)
    elif page == "Doctor & Procedure Analytics":
        render_doctor_analytics(config)
    elif page == "Shift Staffing Console":
        render_shift_console(config)
    elif page == "Emergency Triage Monitor":
        render_emergency_monitor(config)
    elif page == "Medication & Allergy Safety":
        render_medication_safety(config)
    elif page == "Query Workspace":
        render_query_workspace(config)
    else:
        render_validation(config)
