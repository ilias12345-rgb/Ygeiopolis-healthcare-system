USE yg_eupolis_hospital;

-- Row counts for a quick load check.
SELECT 'department' AS table_name, COUNT(*) AS rows_count FROM department
UNION ALL SELECT 'personnel', COUNT(*) FROM personnel
UNION ALL SELECT 'doctor', COUNT(*) FROM doctor
UNION ALL SELECT 'nurse', COUNT(*) FROM nurse
UNION ALL SELECT 'patient', COUNT(*) FROM patient
UNION ALL SELECT 'emergency_visit', COUNT(*) FROM emergency_visit
UNION ALL SELECT 'hospitalization', COUNT(*) FROM hospitalization
UNION ALL SELECT 'procedure_event', COUNT(*) FROM procedure_event
UNION ALL SELECT 'prescription', COUNT(*) FROM prescription;

-- Hospitalizations should have at least one assigned doctor.
SELECT h.hosp_id
FROM hospitalization h
LEFT JOIN hospitalization_doctor hd ON hd.hosp_id = h.hosp_id
WHERE hd.hosp_id IS NULL;

-- Prescriptions should not conflict with patient allergies.
SELECT p.prescription_id, p.patient_amka, p.drug_id, pa.substance_id
FROM prescription p
JOIN drug_active_substance das ON das.drug_id = p.drug_id
JOIN patient_allergy pa
  ON pa.patient_amka = p.patient_amka
 AND pa.substance_id = das.substance_id;

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

-- Bed numbering should be unique per department.
SELECT department_id, bed_number, COUNT(*) AS duplicates_count
FROM bed
GROUP BY department_id, bed_number
HAVING COUNT(*) > 1;

-- Emergency service timestamps should be chronological.
SELECT visit_id
FROM emergency_visit
WHERE service_start_ts < arrival_ts
   OR service_end_ts < service_start_ts;
