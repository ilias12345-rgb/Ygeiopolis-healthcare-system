# Ygeiopolis Healthcare System

Relational database project for the General Hospital "Ygeiopolis" semester assignment, academic year 2025-2026.

The database models hospital departments, staff, shifts, emergency triage, patients, hospitalizations, diagnoses, KEN costing, lab tests, procedures, prescriptions, allergies, evaluations, and image metadata. The current main schema is the Ygeiopolis vol2 design in `sql/install.sql`, implemented with primary keys, foreign keys, unique constraints, domain checks, indexes, views, triggers, and stored procedures.

## Repository Structure

```text
.
├── diagrams/
│   ├── er_diagram.png
│   └── schema.pdf
├── docs/
│   └── exercise-brief-2025-2026.pdf
├── data/
│   ├── reference/
│   └── generated/
├── scripts/
│   ├── generate_data.py
│   └── README.md
├── app.py
├── ui.py
├── queries.py
├── streamlit_app.py
├── .streamlit/
│   └── config.toml
├── sql/
│   ├── install.sql
│   ├── load.sql
│   ├── validation.sql
│   ├── Q01.sql ... Q15.sql
│   ├── Q01_out.txt ... Q15_out.txt
│   └── README.md
└── README.md
```

## Recommended Final Run

The recommended grading path uses the CSV files already included in this repository. The grader should not need to run `scripts/generate_data.py`.

Install MySQL/MariaDB first, then clone or download this final branch and run from the repository root:

```bash
git clone -b final-safe-submission https://github.com/ilias12345-rgb/Ygeiopolis-healthcare-system.git
cd Ygeiopolis-healthcare-system
```

Safest terminal runner:

```bash
bash run_database.sh
```

The script verifies that it is running from the repository root and then executes the same SQL files below.

Manual equivalent:

```bash
mysql -u root -p -e "SET GLOBAL local_infile = 1;"
mysql -u root -p -e "SHOW GLOBAL VARIABLES LIKE 'local_infile';"
mysql -u root -p < sql/install.sql
mysql --local-infile=1 -u root -p < sql/load.sql
mysql -u root -p < sql/validation.sql
```

If the local MySQL user has no password, omit `-p`:

```bash
mysql -u root -e "SET GLOBAL local_infile = 1;"
mysql -u root -e "SHOW GLOBAL VARIABLES LIKE 'local_infile';"
mysql -u root < sql/install.sql
mysql --local-infile=1 -u root < sql/load.sql
mysql -u root < sql/validation.sql
```

The scripts do three things:

1. `install.sql` creates the `yg_eupolis_hospital` database and all schema objects.
2. `load.sql` loads the included CSV data from relative paths under `data/reference` and `data/generated`.
3. `validation.sql` prints row counts and runs problem-detection queries. The problem-detection queries should return zero rows.

## Optional Regeneration

The generator is kept for repeatable testing and for rebuilding the data from official source files. This is optional for grading because the final repository includes generated CSVs.

Install Python dependencies:

```bash
python3 -m pip install -r requirements.txt
```

Windows alternative:

```powershell
py -3 -m pip install -r requirements.txt
```

Place official source files in `data_sources`, then refresh the repository-level `data/` folder:

```bash
python3 scripts/generate_data.py \
  --source-dir data_sources \
  --output-dir .
```

Windows PowerShell alternative:

```powershell
py -3 scripts/generate_data.py `
  --source-dir data_sources `
  --output-dir .
```

This rewrites `data/reference` and `data/generated` in the same portable layout used by `sql/load.sql`. The final database still loads from `data/`; regeneration is only a refresh step.

If you want a separate test bundle instead of changing the repository data, use another output directory:

```bash
python3 scripts/generate_data.py \
  --source-dir data_sources \
  --output-dir hospital_dataset_bundle
```

The generated output contains `data/reference`, `data/generated`, `sql/install.sql`, `sql/load.sql`, `sql/validation.sql`, `dataset_summary.json`, `TABLE_TO_CSV_MAP.csv`, and `QUERY_COVERAGE.csv`. The generator writes only to the directory passed with `--output-dir`; do not pass unrelated folders.

## Optional Streamlit App

A Streamlit application is included for local demonstrations. It opens with an operations console for beds, admissions, shifts, emergency visits, procedures, clinical activity, and monitoring counts. The sidebar menu also includes patient-record lookup, database setup, and the Q01-Q15 SQL workspace.

Application files:

- `app.py`: Streamlit entrypoint.
- `ui.py`: page layout and Streamlit controls.
- `queries.py`: query-file handling, MySQL connection, setup execution, and output saving.
- `streamlit_app.py`: compatibility wrapper that calls `app.py`.
- `.streamlit/config.toml`: application theme.

Install requirements first, then run:

```bash
streamlit run app.py
```

If the `streamlit` command is not available in the terminal:

```bash
python3 -m streamlit run app.py
```

Windows alternative:

```powershell
py -3 -m streamlit run app.py
```

On macOS/Linux, the app auto-fills a common Unix socket path such as `/tmp/mysql.sock` when it exists. On Windows, leave the Unix socket field empty and use the normal host/port connection.

The Streamlit app is optional. The database can always be installed and queried directly from the terminal using the SQL scripts above.

## Troubleshooting Local Infile

- If `LOAD DATA LOCAL INFILE` is rejected, run `mysql -u root -p -e "SET GLOBAL local_infile = 1;"` and reconnect with `mysql --local-infile=1`.
- Confirm the setting with `mysql -u root -p -e "SHOW GLOBAL VARIABLES LIKE 'local_infile';"`.
- If a CSV file is reported as missing, confirm that the command is being run from the repository root.
- `load.sql` intentionally uses relative paths such as `data/reference/icd10_diagnosis.csv` and `data/generated/patient.csv`.

## MySQL Workbench Note

MySQL Workbench is optional and less reliable for this project because it may not resolve relative `LOAD DATA LOCAL INFILE` paths from the SQL file location. The terminal method from the repository root is recommended. If using Workbench, either run from a configured working directory or generate/use an absolute-path load file locally, but do not commit absolute local paths.

## Main SQL Logic

- `personnel` stores common staff data; `doctor`, `nurse`, and `administrative_staff` store role-specific data.
- `department`, `bed`, and `operating_place` describe hospital structure and resources.
- `department_shift` and `shift_assignment` model daily 8-hour rosters.
- `department_shift.shift_status` lets the loader validate a completed shift after all staff assignments have been inserted.
- `emergency_visit` supports triage priority, `WAITING` / `CALLED` status, and FIFO ordering within each urgency level.
- `hospitalization` connects a patient, department, bed, ICD-10 diagnoses, KEN code, admission/discharge dates, and calculated cost.
- `lab_test`, `procedure_event`, `procedure_participant`, and `prescription` model clinical work during hospitalization.
- `patient_allergy`, `drug_active_substance`, and prescription triggers prevent unsafe drug orders.
- `image_asset` and `entity_image` support the website-image requirement.

Important business rules are enforced in SQL:

- doctor supervision cannot be circular;
- residents require a supervisor, and directors cannot have supervisors;
- shift assignment limits, rest time, night-shift limits, and resident supervision are checked by triggers;
- minimum shift composition is checked when a shift is marked `VALID`;
- shift/staff, doctor/procedure, patient history, and prescription-substance reporting are exposed through views;
- procedure rooms and chief surgeons cannot be double-booked;
- procedure place type must match the procedure catalog;
- administrative staff cannot participate in procedures;
- hospitalization cost is calculated from KEN base cost, mean duration, and extra daily cost;
- stored procedures support FIFO emergency selection and shift validation checks.

## Project Assumptions

| Area | Assumption |
| --- | --- |
| RDBMS | The implementation targets MySQL/MariaDB with InnoDB tables. SQL `ENUM`, arrays, JSON, and XML are not used. |
| Identifiers | AMKA values are stored as 11-character digit strings because leading zeroes must be preserved. |
| Controlled values | Staff type, ranks, bed status, shift type, procedure category, and similar fields use `VARCHAR` plus `CHECK` constraints instead of SQL enum types. |
| Patient gender | Generated patient gender uses `MALE` and `FEMALE`; the vol2 schema stores it as `VARCHAR`. |
| Reference data | ICD-10, KEN, medical procedure, and drug reference rows should come from the official files mentioned in the assignment whenever those files are available. |
| Synthetic data | Operational rows such as patients, visits, hospitalizations, shifts, evaluations, and images are generated synthetically but are designed to satisfy the assignment query requirements. |
| EMA drugs | Drug, active-substance, allergy, and prescription rows are loaded only from an official EMA Article 57 workbook. If that file is not provided, these CSVs remain empty so the final database contains no unofficial medication data. |
| Procedure catalog | Procedure codes and names come from the official procedure catalog. The vol2 schema stores the category and required place type. |
| KEN costing | Total hospitalization cost equals the KEN base cost plus extra daily cost only for days beyond the KEN mean duration. |
| Emergency queue | Emergency visits are served by urgency level first, then FIFO by arrival timestamp for equal urgency. |
| Shift coverage | Per-person shift constraints are enforced at insert/update time. Minimum team coverage is generated as complete data, then checked by `shift_composition` when `shift_status` changes to `VALID` and by `sql/validation.sql`. |
| Images | `entity_image` is intentionally generic so images can be attached to departments, staff, patients, procedures, equipment, or future website entities without adding many nullable image columns. |

## Data Generation

The generator creates a deterministic dataset with enough rows for the requested queries. The current defaults generate:

- more than 80 doctors;
- 500 patients;
- 1200 hospitalizations;
- 15 departments;
- 1000 prescriptions when an official EMA Article 57 workbook is supplied; otherwise medication/allergy tables stay empty;
- at least 10 operating/procedure places;
- up to 500 procedure events, depending on room/staff availability;
- 800 lab tests;
- 1500 emergency visits.

The data size can be changed without editing Python:

```bash
python3 scripts/generate_data.py \
  --source-dir data_sources \
  --output-dir hospital_dataset_bundle \
  --patient-count 800 \
  --hospitalization-count 2000 \
  --prescription-count 1800
```

The generated bundle also contains `TABLE_TO_CSV_MAP.csv`, `QUERY_COVERAGE.csv`, `dataset_summary.json`, and portable `sql/install.sql`, `sql/load.sql`, and `sql/validation.sql` files.

## Validation

`sql/validation.sql` includes post-load checks for:

- row counts for important reference, staff, patient, hospitalization, clinical, medication, and evaluation tables;
- hospitalizations without valid patient, department, KEN, or admission ICD-10 diagnosis;
- missing hospitalization doctors;
- bed/department mismatches;
- overlapping bed or patient hospitalizations;
- bed status inconsistencies;
- prescriptions whose drug does not exist;
- prescription allergy conflicts;
- prescription/procedure dates outside hospitalization;
- procedure room overlaps;
- procedure event place type mismatches;
- same doctor participating in overlapping procedures;
- incomplete shift coverage;
- emergency timestamp and referral consistency.

The problem-detection queries should return zero rows after a valid load.

Medication note: if the validation output shows `drug`, `active_substance`, `drug_active_substance`, `patient_allergy`, and `prescription` with zero rows, that is expected only for the current official-only dataset without an EMA Article 57 workbook. It is not a `LOAD DATA` path failure. To populate those tables, provide the official EMA workbook and regenerate the data with `--ema-xlsx`.

## Final Submission Checklist

The assignment PDF asks for the following final structure:

- `README.md`
- `diagrams/er.pdf`
- `diagrams/relational.pdf`
- `docs/report.pdf`
- `sql/install.sql`
- `sql/load.sql`
- `sql/validation.sql`
- `sql/Q01.sql` through `sql/Q15.sql`
- `sql/Q01_out.txt` through `sql/Q15_out.txt`
- `scripts/generate_data.py`
- `data/reference/*.csv`
- `data/generated/*.csv`
- `requirements.txt`
- optional `app.py`, `ui.py`, and `queries.py` if an application/demo UI is submitted

Current repository note: placeholder files exist for query outputs and missing final PDFs. Replace those placeholders with the final query outputs and report/diagram PDFs before the last submission export.
