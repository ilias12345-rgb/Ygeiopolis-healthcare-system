# SQL Guide

This folder contains the database-facing part of the Ygeiopolis Healthcare System.

## Files

- `install.sql`: portable entrypoint for creating the schema.
- `load.sql`: portable relative-path loader for generated CSV data under `data/reference` and `data/generated`.
- `validation.sql`: sanity checks to run after loading data.
- `Q01.sql` through `Q15.sql`: placeholders for the final assignment queries.

## Execution Order

1. Start MySQL/MariaDB.
2. Enable `LOCAL INFILE` in MySQL/MySQL Workbench.
3. Use the included `data/reference` and `data/generated` folders. Regeneration is optional; if needed, run `python3 scripts/generate_data.py --source-dir data_sources --output-dir .` from the project root.
4. Run `install.sql`, `load.sql`, and `validation.sql` from the project root.

Example:

```bash
cd Ygeiopolis-healthcare-system
mysql -u root < sql/install.sql
mysql --local-infile=1 -u root < sql/load.sql
mysql -u root < sql/validation.sql
```

You can also use the root helper script: `bash run_database.sh`.

## Schema Areas

- Organization: departments, beds, operating/procedure rooms.
- Personnel: parent `personnel` table plus doctor/nurse/admin specializations.
- Scheduling: department shifts and shift assignments.
- Patient care: emergency visits and hospitalizations.
- Clinical data: ICD-10 diagnoses, KEN costing, procedure catalog, lab tests, prescriptions, allergies.
- Support data: evaluations and image metadata.

## Business Rules In SQL

The schema intentionally uses triggers for rules that are difficult to express with simple constraints:

- doctor supervision hierarchy validation;
- prescription allergy prevention;
- procedure room and staff overlap prevention;
- procedure room type validation;
- shift supervision, monthly limits, rest time, and night-shift limits;
- automatic hospitalization cost calculation from KEN values.

## Views And Procedures

The schema includes reusable views for common reporting work:

- `patient_history` for hospitalization-patient reporting;
- `prescription_substances` for drug/substance reporting;
- `shift_staff` for department shift staffing;
- `doctor_procedure` for chief doctor procedure reporting.

It also includes stored procedures for FIFO emergency queue handling and shift validation: `FIFO`, `shift_composition`, and `shift_resident_supervisor`.

## Notes

There are no machine-specific absolute paths in the load script. The relative `LOAD DATA LOCAL INFILE` paths are resolved from the folder where the MySQL client is started, so start MySQL from the repository root or from the generated bundle root.
