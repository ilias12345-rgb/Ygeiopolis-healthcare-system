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
│   ├── setup_workbench_absolute.sql
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

If you are using the local exercise folder, rebuild the schema, load the absolute-path CSV bundle, and run validation by opening this file in MySQL Workbench and executing it:

```text
/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/Ygeiopolis-healthcare-system/sql/setup_workbench_absolute.sql
```

To regenerate the local final-data bundle first:

```bash
python3 scripts/generate_data.py \
  --source-dir /Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data \
  --output-dir /Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/rdbms_final_data
```

The generator now keeps clinical references synchronized: hospitalization KEN codes come from the active `ken.csv`, the ICD10-KEN map is filtered against that same KEN table, procedure events use valid procedure/place-type pairs, and drug/allergy/prescription rows use valid drug-substance references.

## Documentation

- [SQL README](sql/README.md) explains the schema and load scripts.
- [Generator README](scripts/README.md) explains the Python data pipeline.
- [Project Review](docs/PROJECT_REVIEW.md) lists what was fixed and what is still missing.
- [Improvements](docs/IMPROVEMENTS.md) tracks completed and remaining improvements.

## Current Status

The project now has a clean structure, aligned schema/load scripts, synchronized generated data, business-rule triggers, workflow procedures, and reusable reporting views. The biggest remaining improvement is to add a final `sql/queries.sql` file with the required exercise queries.
