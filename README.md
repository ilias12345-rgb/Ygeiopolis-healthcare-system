# Ygeiopolis Healthcare System

Database project for a hospital information system. The project models the main entities of a healthcare organization: personnel, departments, beds, shifts, patients, emergency visits, hospitalizations, diagnoses, procedures, lab tests, prescriptions, allergies, evaluations, and supporting image metadata.

The design goal is to show a complete relational model, not only isolated tables. The schema uses primary keys, foreign keys, uniqueness rules, check constraints, indexes, and triggers so the database protects important business logic itself.

## Project Structure

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
│   ├── schema.sql
│   ├── validation.sql
│   ├── load_workbench_absolute.sql
│   └── README.md
└── README.md
```

## Main Logic

The database is organized around six areas:

1. **Hospital organization**: `department`, `bed`, `operating_place`.
2. **Personnel**: `personnel` is the parent table; `doctor`, `nurse`, and `administrative_staff` specialize it.
3. **Scheduling**: `department_shift` defines shifts and `shift_assignment` connects staff to shifts.
4. **Patient flow**: `patient`, `emergency_contact`, `emergency_visit`, and `hospitalization` describe the path from emergency arrival to admission/discharge.
5. **Clinical work**: `icd10_diagnosis`, `ken`, `icd10_ken_map`, `lab_test`, `procedure_event`, `procedure_participant`, and `prescription`.
6. **Quality/support data**: `hospitalization_evaluation`, `image_asset`, and `entity_image`.

Important rules are enforced in SQL:

- doctors cannot supervise themselves or form supervision cycles;
- resident doctors must have appropriate supervision;
- prescriptions are blocked when the patient is allergic to a drug substance;
- procedures cannot overlap in the same operating/procedure room;
- staff cannot be assigned to overlapping procedure participation;
- administrative staff cannot participate in medical procedures;
- shift limits, rest-time rules, and night-shift limits are checked;
- hospitalization cost is calculated from KEN cost rules.

## How To Run

Create the database schema:

```bash
mysql -u root -p < sql/schema.sql
```

If you already have the generated CSV files at the absolute paths used during the exercise, load them in MySQL Workbench with:

```sql
SOURCE sql/load_workbench_absolute.sql;
```

For a reproducible run, generate a fresh data bundle:

```bash
python3 scripts/generate_data.py --source-dir . --output-dir hospital_dataset_bundle
mysql --local-infile=1 -u root -p < hospital_dataset_bundle/sql/load.sql
```

The generator expects the official ICD-10/procedure source workbooks to be available in the source directory. If they are not included, keep using the existing generated CSV bundle referenced by the Workbench loader.

## Documentation

- [SQL README](sql/README.md) explains the schema and load scripts.
- [Generator README](scripts/README.md) explains the Python data pipeline.
- [Project Review](docs/PROJECT_REVIEW.md) lists what was fixed and what is still missing.
- [Improvements](docs/IMPROVEMENTS.md) proposes FIFO, views, stored procedures, validation, and optimization additions.

## Current Status

The project now has a clean structure and the main schema has been aligned with the generated data/load script. The biggest remaining improvement is to add a final `sql/queries.sql` file with the required exercise queries and a reproducible `data/` bundle or clear source-data instructions.
