# Ygeiopolis Healthcare System

Relational database project for the General Hospital "Ygeiopolis" semester assignment, academic year 2025-2026.

The database models hospital departments, staff, shifts, emergency triage, patients, hospitalizations, diagnoses, KEN costing, lab tests, procedures, prescriptions, allergies, evaluations, and image metadata. The current main schema is the Ygeiopolis vol2 design in `sql/schema.sql` / `sql/DB_ygeiopolis_new2.sql`, implemented with primary keys, foreign keys, unique constraints, domain checks, indexes, views, triggers, and stored procedures.

## Repository Structure

```text
.
├── assets/
│   └── er_diagram.png
├── docs/
│   ├── exercise-brief-2025-2026.pdf
│   ├── schema.pdf
│   ├── PROJECT_REVIEW.md
│   └── IMPROVEMENTS.md
├── scripts/
│   ├── generate_data.py
│   └── README.md
├── sql/
│   ├── install.sql
│   ├── schema.sql
│   ├── DB_ygeiopolis_new2.sql
│   ├── setup.sql
│   ├── load.sql
│   ├── validation.sql
│   └── README.md
└── README.md
```

## How To Run

### Prerequisites

- MySQL or MariaDB installed and running.
- `LOCAL INFILE` enabled in the MySQL client/server, because the loader uses `LOAD DATA LOCAL INFILE`.
- Python 3 with the packages listed in `requirements.txt`.
- Official source files from the assignment available in a local folder.

Install Python dependencies if needed:

```bash
python3 -m pip install -r requirements.txt
```

If MySQL is installed but not running, start it first. On a Homebrew macOS setup this is usually:

```bash
brew services start mysql
```

The project has two supported ways to run:

1. Generate a portable data bundle, then run it from the bundle folder.
2. Generate/copy `data/reference` and `data/generated` into this repository, then run from the project folder.

For a clean run on another laptop, use the first option.

### 1. Prepare Source Files

Create a folder named `data_sources` and place the official source files from the assignment there, for example ICD-10, KEN, ICD10-KEN mapping, medical procedure catalog, and optionally the EMA Article 57 workbook.

```bash
mkdir -p data_sources
```

If the files are somewhere else, pass that folder to `--source-dir` instead of `data_sources`.

### 2. Generate A Portable Data Bundle

From the repository root:

```bash
python3 scripts/generate_data.py \
  --source-dir data_sources \
  --output-dir hospital_dataset_bundle
```

This creates a self-contained folder named `hospital_dataset_bundle` with:

- `data/reference/*.csv`
- `data/generated/*.csv`
- `sql/install.sql`
- `sql/schema.sql`
- `sql/load.sql`
- `sql/setup.sql`
- `sql/validation.sql`
- dataset metadata files

### 3. Load Everything Into MySQL

From inside the generated bundle root:

```bash
cd hospital_dataset_bundle
mysql --local-infile=1 -u root -p < sql/setup.sql
```

`setup.sql` runs the schema installer, loads all generated CSVs, and then runs validation.

If MySQL rejects `LOAD DATA LOCAL INFILE`, enable it for the session/client and retry:

```bash
mysql --local-infile=1 -u root -p
```

In MySQL Workbench, enable `OPT_LOCAL_INFILE` / `local_infile` before running the setup script.

### Manual Alternative

```bash
mysql -u root -p < sql/install.sql
mysql --local-infile=1 -u root -p < sql/load.sql
mysql -u root -p yg_eupolis_hospital < sql/validation.sql
```

### Running From This Repository Instead

If you copy or generate the CSV folders directly into this repository as `data/reference` and `data/generated`, run from the repository root:

```bash
mysql --local-infile=1 -u root -p < sql/setup.sql
```

The repository does not store generated CSV data by default because the bundle can be large and may contain regenerated reference extracts.

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
- `diagrams/er.pdf`
- `diagrams/relational.pdf`
- `sql/install.sql`
- `sql/load.sql`
- `sql/Q01.sql` through `sql/Q15.sql`
- `sql/Q01_out.txt` through `sql/Q15_out.txt`
- `docs/report.pdf`, including the required EXPLAIN / FORCE INDEX comparison for Q4 and Q6
- optional `code/` folder if an application is submitted

Current repository note: the portable install/load/setup scripts and validation logic are present, but the final per-query SQL/output files and the Q4/Q6 report material still need to be prepared for the exact submission format.

## AI Assistance Note

OpenAI Codex was used as an assistant for schema review, SQL hardening, validation-script expansion, and README cleanup. The project design, final verification, and submitted results should be reviewed by the team before delivery.
