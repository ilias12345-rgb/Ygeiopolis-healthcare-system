# Improvements

This document tracks the improvement plan for the database project.

## Completed

### 1. FIFO Emergency Queue

Implemented in `sql/schema.sql`.

- `v_emergency_fifo_queue` lists unstarted emergency visits by priority FIFO order: `emergency_level`, then `arrival_ts`, then `visit_id`.
- `sp_next_emergency_visit(department_id)` returns the next pending emergency visit.
- `sp_start_emergency_service(visit_id)` starts service safely.
- `sp_finish_emergency_service(visit_id, disposition, referred_department_id)` completes the visit and records the outcome.

The project uses priority FIFO because hospital triage normally serves higher-severity cases first, then preserves arrival order within the same severity level.

### 2. Useful Views

Implemented in `sql/schema.sql`.

- `v_current_bed_status`: bed status by department, including active hospitalization context.
- `v_active_hospitalizations`: currently admitted patients with department, bed, and KEN details.
- `v_patient_history`: patient demographics joined with hospitalization, diagnosis, KEN, and cost data.
- `v_doctor_workload`: hospitalization, procedure, and shift counts per doctor.
- `v_department_occupancy`: total, occupied, available, maintenance beds, and occupancy percentage.
- `v_prescription_substances`: prescriptions expanded to active substances for allergy and drug queries.
- `v_shift_roster`: readable shift roster with staff name, type, role, and rank/detail.

### 3. Stored Procedures

Implemented in `sql/schema.sql`.

- `sp_admit_patient`: admits a patient, allocates an available bed, assigns the primary doctor, and marks the bed occupied.
- `sp_discharge_patient`: records discharge, lets the KEN trigger recalculate cost, and releases the bed when appropriate.
- `sp_prescribe_drug_safely`: inserts a prescription after checking allergy conflicts.
- `sp_schedule_procedure`: schedules a procedure while existing triggers enforce room, surgeon, and place-type rules.
- `sp_add_procedure_participant`: adds procedure participants while existing triggers enforce participant rules.
- `sp_assign_staff_to_shift`: assigns staff to a shift while existing triggers enforce shift rules.
- `sp_record_evaluation`: records or updates a post-discharge hospitalization evaluation.

## Remaining

### 4. Validation Scripts

Extend `sql/validation.sql` with:

- broader row counts per table;
- orphan detection for key foreign-key relationships;
- occupied beds without active hospitalization;
- active hospitalization without occupied bed status;
- emergency visits with inconsistent timestamps;
- negative trigger tests that intentionally attempt invalid inserts and confirm they fail.

### 5. Query File

Add `sql/queries.sql` containing the final exercise answers. Keep each query labelled:

```sql
-- Q1: ...
SELECT ...
```

### 6. Optimization

After `sql/queries.sql` exists, run `EXPLAIN` on each final query. Keep the indexes that support the final workload and remove speculative indexes that do not help.
