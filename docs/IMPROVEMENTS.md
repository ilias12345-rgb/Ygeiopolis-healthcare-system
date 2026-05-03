# Proposed Improvements

## 1. FIFO Emergency Queue

Add a queue model for emergency visits so triage can be handled cleanly.

Recommended objects:

- `v_emergency_fifo_queue`: pending visits ordered by `emergency_level`, then `arrival_ts`.
- `sp_next_emergency_visit(department_id)`: returns the next patient to serve.
- `sp_start_emergency_service(visit_id)`: sets `service_start_ts`.
- `sp_finish_emergency_service(visit_id, disposition, referred_department_id)`: sets `service_end_ts` and final outcome.

Important choice: strict FIFO means arrival order only. Hospital triage usually means priority FIFO: emergency level first, arrival time second.

## 2. Useful Views

Add views for repeated reporting queries:

- `v_current_bed_status`: department, bed type, bed number, current status.
- `v_active_hospitalizations`: patients currently admitted.
- `v_patient_history`: patient demographics plus hospitalization, diagnosis, KEN, and cost summary.
- `v_doctor_workload`: hospitalizations, procedures, and shifts per doctor.
- `v_department_occupancy`: total beds, occupied beds, available beds, occupancy percentage.
- `v_prescription_substances`: prescription joined with active substances for allergy/query work.
- `v_shift_roster`: one readable row per shift assignment with staff name and role.

## 3. Stored Procedures

Add procedures for workflows that should be consistent every time:

- admit a patient and allocate a bed;
- discharge a patient and calculate final KEN cost;
- prescribe a drug safely;
- schedule a procedure with room/participant checks;
- assign staff to a shift;
- record an evaluation after discharge.

## 4. Validation Scripts

Extend `sql/validation.sql` with checks such as:

- row counts per table;
- orphan detection for foreign keys;
- hospitalizations without doctors;
- occupied beds without active hospitalization;
- emergency visits with inconsistent timestamps;
- prescriptions that would violate allergies;
- negative trigger tests that intentionally attempt invalid inserts and confirm they fail.

## 5. Query File

Add `sql/queries.sql` containing the final exercise answers. Keep each query labelled:

```sql
-- Q1: ...
SELECT ...
```

This will make the project much easier to grade and explain.

## 6. Optimization

After `sql/queries.sql` exists, run `EXPLAIN` on each query and keep only indexes that help the final workload. This is cleaner than keeping speculative indexes.
