# SQL Guide

This folder contains the database-facing part of the Ygeiopolis Healthcare System.

## Files

- `install.sql`: portable entrypoint for creating the schema.
- `schema.sql`: creates the `yg_eupolis_hospital` database, tables, constraints, indexes, views, triggers, and stored procedures.
- `load.sql`: portable relative-path loader for generated CSV data under `data/reference` and `data/generated`.
- `setup.sql`: portable schema + load + validation script. Run it from the project or generated bundle root.
- `validation.sql`: sanity checks to run after loading data.

## Execution Order

1. Enable `LOCAL INFILE` in MySQL/MySQL Workbench.
2. Put the generated CSV folders at `data/reference` and `data/generated`.
3. Run `setup.sql` from the project or bundle root.

Example:

```bash
mysql --local-infile=1 -u root -p < sql/setup.sql
```

To run the pieces manually:

```bash
mysql -u root -p < sql/install.sql
mysql --local-infile=1 -u root -p < sql/load.sql
mysql -u root -p yg_eupolis_hospital < sql/validation.sql
```

## Schema Areas

- Organization: departments, beds, operating/procedure rooms.
- Personnel: parent `personnel` table plus doctor/nurse/admin specializations.
- Scheduling: department shifts and shift assignments.
- Patient care: emergency visits and hospitalizations.
- Clinical data: ICD-10 diagnoses, KEN costing, procedure duration/cost definitions, lab tests, prescriptions, allergies.
- Support data: evaluations and image metadata.

## Business Rules In SQL

The schema intentionally uses triggers for rules that are difficult to express with simple constraints:

- doctor supervision hierarchy validation;
- prescription allergy prevention;
- procedure room and staff overlap prevention;
- procedure room type validation;
- hospitalization bed/patient overlap prevention;
- prescription and procedure timing inside the hospitalization period;
- shift supervision, monthly limits, rest time, and night-shift limits;
- automatic hospitalization cost calculation from KEN values.

## Views And Procedures

The schema includes reusable views for common reporting work:

- emergency FIFO queue;
- current bed status and department occupancy;
- active hospitalizations and patient history;
- doctor workload and shift roster;
- prescription-substance analysis for allergy checks.

It also includes stored procedures for common workflows: emergency queue handling, admission, discharge, safe prescription, procedure scheduling, participant assignment, shift assignment, and post-discharge evaluation. Admission, discharge, and emergency-service procedures use explicit transactions so multi-step state changes commit or roll back together.

## Notes

There are no machine-specific absolute paths in the load/setup scripts. If loading from MySQL Workbench, open the project or generated bundle as the working folder before running `sql/setup.sql`, or run the three manual commands above from a terminal.
