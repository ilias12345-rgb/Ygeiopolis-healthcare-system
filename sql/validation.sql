USE yg_eupolis_hospital;

-- Use a fixed dataset date so validation is reproducible on every laptop.
-- The generated bed statuses are synchronized to this same timestamp.
SET @validation_as_of_ts = '2026-05-12 12:00:00';

-- Row counts for a quick load check.
SELECT 'department' AS table_name, COUNT(*) AS rows_count FROM department
UNION ALL SELECT 'personnel', COUNT(*) FROM personnel
UNION ALL SELECT 'doctor', COUNT(*) FROM doctor
UNION ALL SELECT 'nurse', COUNT(*) FROM nurse
UNION ALL SELECT 'administrative_staff', COUNT(*) FROM administrative_staff
UNION ALL SELECT 'patient', COUNT(*) FROM patient
UNION ALL SELECT 'bed', COUNT(*) FROM bed
UNION ALL SELECT 'department_shift', COUNT(*) FROM department_shift
UNION ALL SELECT 'shift_assignment', COUNT(*) FROM shift_assignment
UNION ALL SELECT 'emergency_visit', COUNT(*) FROM emergency_visit
UNION ALL SELECT 'hospitalization', COUNT(*) FROM hospitalization
UNION ALL SELECT 'hospitalization_doctor', COUNT(*) FROM hospitalization_doctor
UNION ALL SELECT 'lab_test', COUNT(*) FROM lab_test
UNION ALL SELECT 'procedure_catalog', COUNT(*) FROM procedure_catalog
UNION ALL SELECT 'procedure_event', COUNT(*) FROM procedure_event
UNION ALL SELECT 'procedure_participant', COUNT(*) FROM procedure_participant
UNION ALL SELECT 'prescription', COUNT(*) FROM prescription
UNION ALL SELECT 'hospitalization_evaluation', COUNT(*) FROM hospitalization_evaluation;

-- The following checks should return zero rows.

-- Hospitalizations should have at least one assigned doctor.
SELECT h.hosp_id
FROM hospitalization h
LEFT JOIN hospitalization_doctor hd ON hd.hosp_id = h.hosp_id
WHERE hd.hosp_id IS NULL;

-- Hospitalizations should not assign a bed from another department.
SELECT h.hosp_id, h.department_id AS hospitalization_department_id, b.department_id AS bed_department_id
FROM hospitalization h
JOIN bed b ON b.bed_id = h.bed_id
WHERE h.department_id <> b.department_id;

-- Beds should not be double-booked by overlapping hospitalizations.
SELECT a.hosp_id AS hospitalization_a,
       b.hosp_id AS hospitalization_b,
       a.bed_id
FROM hospitalization a
JOIN hospitalization b
  ON a.bed_id = b.bed_id
 AND a.hosp_id < b.hosp_id
 AND a.admission_ts < COALESCE(b.discharge_ts, '9999-12-31 23:59:59')
 AND COALESCE(a.discharge_ts, '9999-12-31 23:59:59') > b.admission_ts;

-- Patients should not have overlapping hospitalizations.
SELECT a.hosp_id AS hospitalization_a,
       b.hosp_id AS hospitalization_b,
       a.patient_amka
FROM hospitalization a
JOIN hospitalization b
  ON a.patient_amka = b.patient_amka
 AND a.hosp_id < b.hosp_id
 AND a.admission_ts < COALESCE(b.discharge_ts, '9999-12-31 23:59:59')
 AND COALESCE(a.discharge_ts, '9999-12-31 23:59:59') > b.admission_ts;

-- Occupied beds should have a current hospitalization, and current hospitalizations should use occupied beds.
SELECT b.bed_id, b.department_id, b.bed_status
FROM bed b
LEFT JOIN hospitalization h
  ON h.bed_id = b.bed_id
 AND h.admission_ts <= @validation_as_of_ts
 AND (h.discharge_ts IS NULL OR h.discharge_ts > @validation_as_of_ts)
WHERE b.bed_status = 'OCCUPIED'
  AND h.hosp_id IS NULL;

SELECT h.hosp_id, h.bed_id, b.bed_status
FROM hospitalization h
JOIN bed b ON b.bed_id = h.bed_id
WHERE h.admission_ts <= @validation_as_of_ts
  AND (h.discharge_ts IS NULL OR h.discharge_ts > @validation_as_of_ts)
  AND b.bed_status <> 'OCCUPIED';

-- Prescriptions should not conflict with patient allergies.
SELECT p.prescription_id, p.patient_amka, p.drug_id, pa.substance_id
FROM prescription p
JOIN drug_active_substance das ON das.drug_id = p.drug_id
JOIN patient_allergy pa
  ON pa.patient_amka = p.patient_amka
 AND pa.substance_id = das.substance_id;

-- Prescriptions should stay within their hospitalization period.
SELECT p.prescription_id, p.hosp_id, p.start_datetime, p.end_datetime, h.admission_ts, h.discharge_ts
FROM prescription p
JOIN hospitalization h
  ON h.hosp_id = p.hosp_id
 AND h.patient_amka = p.patient_amka
WHERE p.start_datetime < h.admission_ts
   OR (h.discharge_ts IS NOT NULL AND p.start_datetime > h.discharge_ts)
   OR (p.end_datetime IS NOT NULL AND p.end_datetime < h.admission_ts)
   OR (p.end_datetime IS NOT NULL AND h.discharge_ts IS NOT NULL AND p.end_datetime > h.discharge_ts);

-- Procedure rooms should not have overlapping events.
SELECT a.procedure_event_id AS event_a,
       b.procedure_event_id AS event_b,
       a.place_id
FROM procedure_event a
JOIN procedure_event b
  ON a.place_id = b.place_id
 AND a.procedure_event_id < b.procedure_event_id
 AND a.start_ts < b.end_ts
 AND a.end_ts > b.start_ts;

-- Procedure events should stay inside their hospitalization period.
SELECT pe.procedure_event_id, pe.hosp_id, pe.start_ts, pe.end_ts, h.admission_ts, h.discharge_ts
FROM procedure_event pe
JOIN hospitalization h ON h.hosp_id = pe.hosp_id
WHERE pe.start_ts < h.admission_ts
   OR (h.discharge_ts IS NOT NULL AND pe.end_ts > h.discharge_ts);

-- Procedure catalog rows should include valid category and place data.
SELECT procedure_code, procedure_category, required_place_type
FROM procedure_catalog
WHERE procedure_category NOT IN ('SURGICAL', 'DIAGNOSTIC', 'THERAPEUTIC')
   OR required_place_type NOT IN ('OPERATING_ROOM', 'PROCEDURE_ROOM');

-- Department shifts should meet the required staffing coverage.
SELECT ds.shift_id,
       ds.department_id,
       ds.shift_date,
       ds.shift_type,
       SUM(p.personnel_type = 'DOCTOR') AS doctor_count,
       SUM(p.personnel_type = 'NURSE') AS nurse_count,
       SUM(p.personnel_type = 'ADMIN') AS admin_count
FROM department_shift ds
LEFT JOIN shift_assignment sa ON sa.shift_id = ds.shift_id
LEFT JOIN personnel p ON p.amka = sa.personnel_amka
GROUP BY ds.shift_id, ds.department_id, ds.shift_date, ds.shift_type
HAVING doctor_count < 3
    OR nurse_count < 6
    OR admin_count < 2;

-- Emergency service timestamps should be chronological.
SELECT visit_id
FROM emergency_visit
WHERE service_start_ts IS NOT NULL
  AND service_start_ts < arrival_ts;

-- Emergency disposition/referral consistency.
SELECT visit_id, disposition, referred_department_id
FROM emergency_visit
WHERE (disposition = 'HOSPITALIZED' AND referred_department_id IS NULL)
   OR (disposition = 'DISCHARGED' AND referred_department_id IS NOT NULL);
