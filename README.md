# Ygeiopolis Healthcare System

Relational database project for the General Hospital "Ygeiopolis" semester assignment, academic year 2025-2026.

The database models hospital departments, staff, shifts, emergency triage, patients, hospitalizations, diagnoses, KEN costing, lab tests, procedures, prescriptions, allergies, evaluations, and image metadata. The current main schema is the Ygeiopolis vol2 design in `sql/schema.sql`, implemented with primary keys, foreign keys, unique constraints, domain checks, indexes, views, triggers, and stored procedures.

## Repository Structure

```text
.
├── diagrams/
│   ├── er_diagram.png
│   └── schema.pdf
├── docs/
│   └── exercise-brief-2025-2026.pdf
├── scripts/
│   ├── generate_data.py
│   └── README.md
├── sql/
│   ├── install.sql
│   ├── schema.sql
│   ├── setup.sql
│   ├── load.sql
│   ├── validation.sql
│   ├── Q01.sql ... Q15.sql
│   └── README.md
├── streamlit_app.py
└── README.md
```

## How To Run On A New Laptop

The recommended run path is to generate a portable bundle and execute the database setup from inside that bundle. This avoids absolute paths and lets the same commands work on another machine.

### 1. Install Requirements

Install the following before running the project:

- Python 3
- MySQL or MariaDB
- Git, if the project is cloned from GitHub

On macOS with Homebrew, a typical setup is:

```bash
brew install python mysql git
brew services start mysql
```

On Windows or Linux, install Python 3 and MySQL/MariaDB using the normal installer/package manager for that system, then make sure the `python3`, `pip`, and `mysql` commands are available from the terminal.

On Windows, the Python command may be `py -3` instead of `python3`. If so, use `py -3` in the Python commands below.

### 2. Get The Project

Clone the repository, then enter the project folder:

```bash
git clone https://github.com/ilias12345-rgb/Ygeiopolis-healthcare-system.git
cd Ygeiopolis-healthcare-system
```

If the project was shared as a ZIP file instead, extract it and open a terminal inside the extracted `Ygeiopolis-healthcare-system` folder.

### 3. Install Python Packages

From the project root:

```bash
python3 -m pip install -r requirements.txt
```

Windows alternative:

```powershell
py -3 -m pip install -r requirements.txt
```

The generator uses these packages to read the official Excel/Word source files and produce CSV data.

### 4. Add The Official Source Files

Create a folder named `data_sources` in the project root:

```bash
mkdir -p data_sources
```

Place the official assignment files in that folder, for example:

- ICD-10 diagnosis file
- KEN file
- ICD-10 to KEN mapping file
- medical procedure catalog
- optional EMA Article 57 drug workbook

If the official files are stored somewhere else, keep them there and pass that path to `--source-dir` in the next step.

### 5. Generate The Portable Data Bundle

From the project root, run:

```bash
python3 scripts/generate_data.py \
  --source-dir data_sources \
  --output-dir hospital_dataset_bundle
```

Windows PowerShell alternative:

```powershell
py -3 scripts/generate_data.py `
  --source-dir data_sources `
  --output-dir hospital_dataset_bundle
```

This creates `hospital_dataset_bundle`, which contains everything needed for loading:

- `data/reference/*.csv`
- `data/generated/*.csv`
- `sql/install.sql`
- `sql/schema.sql`
- `sql/load.sql`
- `sql/setup.sql`
- `sql/validation.sql`
- metadata files such as `dataset_summary.json`, `TABLE_TO_CSV_MAP.csv`, and `QUERY_COVERAGE.csv`

If the official files are not in `data_sources`, use:

```bash
python3 scripts/generate_data.py \
  --source-dir /path/to/official/files \
  --output-dir hospital_dataset_bundle
```

Windows paths also work. Example:

```powershell
py -3 scripts/generate_data.py `
  --source-dir C:\path\to\official\files `
  --output-dir hospital_dataset_bundle
```

### 6. Load The Database

Move into the generated bundle:

```bash
cd hospital_dataset_bundle
```

Then run the full setup:

```bash
mysql --local-infile=1 -u root -p < sql/setup.sql
```

Enter the MySQL password when asked. If the local MySQL user has no password, use:

```bash
mysql --local-infile=1 -u root < sql/setup.sql
```

The `setup.sql` script does three things:

1. creates the `yg_eupolis_hospital` database;
2. loads all generated CSV data with relative paths;
3. runs validation queries.

The first output should show row counts for the main tables. The validation queries after that should return zero rows.

### 7. Run The Scripts Manually If Needed

The full setup is the easiest option, but the same process can be run in three separate steps from inside `hospital_dataset_bundle`:

```bash
mysql -u root -p < sql/install.sql
mysql --local-infile=1 -u root -p < sql/load.sql
mysql -u root -p yg_eupolis_hospital < sql/validation.sql
```

### 8. MySQL Workbench Option

If using MySQL Workbench:

1. Enable `local_infile` / `OPT_LOCAL_INFILE` for the connection.
2. Open `hospital_dataset_bundle/sql/setup.sql`.
3. Make sure the working directory is the generated bundle root, because `LOAD DATA LOCAL INFILE` uses relative paths such as `data/generated/patient.csv`.
4. Run the script.

Running from terminal is recommended because relative file paths are more predictable.

### Troubleshooting

- If `LOAD DATA LOCAL INFILE` is rejected, reconnect with `mysql --local-infile=1` and make sure the MySQL server allows local infile loading.
- If a CSV file is reported as missing, confirm that the command is being run from inside `hospital_dataset_bundle`, not from another folder.
- If `python3` cannot import a package, rerun `python3 -m pip install -r requirements.txt`.
- If MySQL cannot connect, start the MySQL/MariaDB service and confirm the username/password.
- If official source files have different names, keep them in one folder and pass that folder through `--source-dir`; the generator searches for the known assignment files recursively.

### Running From This Repository Instead

The repository itself does not store generated CSV data by default. If `data/reference` and `data/generated` are copied into the project root, the same full setup can also be run from the repository root:

```bash
mysql --local-infile=1 -u root -p < sql/setup.sql
```

## Optional Streamlit UI

A small Streamlit helper is included for local demonstrations. It can run `sql/setup.sql`, edit/save the `Q01.sql` to `Q15.sql` query files, and execute queries against the loaded MySQL database.

Install requirements first, then run:

```bash
streamlit run streamlit_app.py
```

Windows alternative:

```powershell
py -3 -m streamlit run streamlit_app.py
```

The Streamlit app is optional. The database can always be installed and queried directly from the terminal using the SQL scripts above.

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
| EMA drugs | If the EMA Article 57 workbook is not provided, the generator creates a clearly marked demo drug/substance fallback so allergy and prescription logic can still be tested. Final submission should replace it with EMA-derived data if required. |
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
- 1000 prescriptions;
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

The generated bundle also contains `TABLE_TO_CSV_MAP.csv`, `QUERY_COVERAGE.csv`, `dataset_summary.json`, and portable `sql/install.sql`, `sql/load.sql`, and `sql/setup.sql` files.

## Validation

`sql/validation.sql` includes post-load checks for:

- row counts;
- missing hospitalization doctors;
- bed/department mismatches;
- overlapping bed or patient hospitalizations;
- bed status inconsistencies;
- prescription allergy conflicts;
- prescription/procedure dates outside hospitalization;
- procedure room overlaps;
- incomplete shift coverage;
- emergency timestamp and referral consistency.

The problem-detection queries should return zero rows after a valid load.

## Final Submission Checklist

The assignment PDF asks for the following final structure:

- `README.md`
- `diagrams/er_diagram.png`
- `diagrams/schema.pdf`
- `sql/install.sql`
- `sql/load.sql`
- `sql/Q01.sql` through `sql/Q15.sql`
- `sql/Q01_out.txt` through `sql/Q15_out.txt`
- `docs/report.pdf`, including the required EXPLAIN / FORCE INDEX comparison for Q4 and Q6
- optional `streamlit_app.py` if an application/demo UI is submitted

Current repository note: the portable install/load/setup scripts and validation logic are present, but the final per-query SQL/output files and the Q4/Q6 report material still need to be prepared for the exact submission format.
