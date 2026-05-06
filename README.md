# Ygeiopolis Healthcare System

Ygeiopolis is a relational database project for a hospital information system. It models the operational and clinical data of a healthcare organization, including personnel, departments, beds, shifts, patients, emergency visits, hospitalizations, diagnoses, procedures, lab tests, prescriptions, allergies, evaluations, and image metadata.

The project is designed as a complete database deliverable. The schema uses primary keys, foreign keys, unique constraints, check constraints, indexes, triggers, reporting views, and stored procedures so the database protects important business rules directly.

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
│   ├── schema.sql
│   ├── validation.sql
│   ├── load_workbench_absolute.sql
│   └── README.md
└── README.md
```

## Main Logic

The database is organized around six functional areas:

1. **Hospital organization**: `department`, `bed`, `operating_place`.
2. **Personnel**: `personnel` is the parent table; `doctor`, `nurse`, and `administrative_staff` specialize it.
3. **Scheduling**: `department_shift` defines shifts and `shift_assignment` connects staff to shifts.
4. **Patient flow**: `patient`, `emergency_contact`, `emergency_visit`, and `hospitalization` describe the path from emergency arrival to admission/discharge.
5. **Clinical work**: `icd10_diagnosis`, `ken`, `icd10_ken_map`, `lab_test`, `procedure_event`, `procedure_participant`, and `prescription`.
6. **Quality/support data**: `hospitalization_evaluation`, `image_asset`, and `entity_image`.

Important rules are enforced inside SQL:

- doctors cannot supervise themselves or form supervision cycles;
- resident doctors must have appropriate supervision;
- prescriptions are blocked when the patient is allergic to a drug substance;
- procedures cannot overlap in the same operating/procedure room;
- staff cannot be assigned to overlapping procedure participation;
- administrative staff cannot participate in medical procedures;
- shift limits, rest-time rules, and night-shift limits are enforced;
- hospitalization cost is calculated from KEN cost rules.

The schema also includes workflow objects:

- FIFO-style emergency queue view and procedures;
- reporting views for beds, occupancy, active admissions, patient history, doctor workload, prescriptions, and shift rosters;
- stored procedures for admission, discharge, prescription, procedure scheduling, shift assignment, and post-discharge evaluation.

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

The generator expects the official ICD-10 and procedure source workbooks to be available in the source directory. If they are not included, keep using the generated CSV bundle referenced by the Workbench loader.

## Documentation

- [SQL README](sql/README.md) explains the schema and load scripts.
- [Generator README](scripts/README.md) explains the Python data pipeline.
- [Project Review](docs/PROJECT_REVIEW.md) lists what was fixed and what is still missing.
- [Improvements](docs/IMPROVEMENTS.md) tracks completed and remaining improvements.

## Current Status

The project now has a clean structure, aligned schema/load scripts, business-rule triggers, workflow procedures, and reusable reporting views. The biggest remaining improvement is to add a final `sql/queries.sql` file with the required exercise queries and either a reproducible `data/` bundle or clear source-data instructions.
