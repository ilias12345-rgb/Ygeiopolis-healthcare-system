# Project Review

## Improvements Already Made

- Reorganized the repository into `sql/`, `scripts/`, `docs/`, and `assets/`.
- Replaced the empty root README with a project explanation, run instructions, and structure map.
- Added SQL and generator-specific README files.
- Added `sql/validation.sql` with post-load sanity checks.
- Aligned `sql/schema.sql` with the loader/generator columns:
  - added `icd10_ken_map`;
  - added `bed.bed_number`;
  - added `emergency_visit.service_end_ts`;
  - added `hospitalization.emergency_visit_id`;
  - added `hospitalization_doctor.doctor_role` and `is_primary`;
  - added `lab_test.result_numeric`, `result_unit`, and `cost`;
  - added `procedure_participant.participant_role`.
- Fixed trigger issues that would cause SQL creation/runtime problems:
  - broken aliases in monthly shift limit triggers;
  - typo `shft_date`;
  - non-doctor staff lookup in resident-supervisor trigger;
  - missing no-row handling in rest-time trigger;
  - update logic for night-shift checks;
  - added hospitalization cost calculation on insert as well as update.

## What Is Still Missing

- A final `sql/queries.sql` file with the exercise queries, ideally numbered Q1-Q15.
- A reproducible `data/` bundle, or clear instructions for where the required official source workbooks must be placed.
- Official KEN and EMA drug data replacement if the final exercise requires only official reference data.
- More negative trigger test cases, for example insert attempts that should fail.
- More views and stored procedures for common workflows.
- A short submission note explaining which data is official, which is synthetic, and why.

## Code Quality Notes

- The schema is strong in relational structure: primary keys, foreign keys, check constraints, indexes, and business-rule triggers are all present.
- The generator is useful because it creates query-driven data instead of random-only data.
- Some trigger logic is complex. For final submission, add small SQL test cases proving each trigger blocks invalid data.
- Some indexes are marked with comments such as "maybe delete". These should be checked with `EXPLAIN` once the final query file exists.
