-- Robust generated loader with absolute local Mac paths for MySQL Workbench.
-- In Workbench, ensure OPT_LOCAL_INFILE / local_infile is enabled.
-- Paths point to the coherent hospital_dataset_bundle folder whose reference
-- and generated CSV files were produced together.
USE yg_eupolis_hospital;
SET FOREIGN_KEY_CHECKS = 1;

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/reference/icd10_diagnosis.csv'
INTO TABLE icd10_diagnosis
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(icd10_code, icd10_description);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/reference/ken.csv'
INTO TABLE ken
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(ken_code, ken_description, basic_cost, mean_duration_days, extra_daily_cost);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/reference/icd10_ken_map.csv'
INTO TABLE icd10_ken_map
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(mdc_code, ken_code, icd10_code_prefix);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/reference/procedure_catalog.csv'
INTO TABLE procedure_catalog
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(procedure_code, procedure_name, procedure_category, required_place_type);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/reference/lab_test_catalog.csv'
INTO TABLE lab_test_catalog
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(test_code, test_name, test_type);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/reference/drug.csv'
INTO TABLE drug
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(drug_id, drug_name);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/reference/active_substance.csv'
INTO TABLE active_substance
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(substance_id, substance_name);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/reference/drug_active_substance.csv'
INTO TABLE drug_active_substance
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(drug_id, substance_id);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/personnel.csv'
INTO TABLE personnel
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(amka, first_name, last_name, age, email, phone_number, hiring_date, personnel_type);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/doctor.csv'
INTO TABLE doctor
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@amka, @license_number, @specialization, @doctor_rank, @supervisor_amka)
SET
    amka = @amka,
    license_number = @license_number,
    specialization = @specialization,
    doctor_rank = @doctor_rank,
    supervisor_amka = NULLIF(@supervisor_amka, '');

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/department.csv'
INTO TABLE department
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@department_id, @department_name, @description, @bed_capacity, @floor_building, @manager_doctor_amka)
SET
    department_id = @department_id,
    department_name = @department_name,
    description = NULLIF(@description, ''),
    bed_capacity = @bed_capacity,
    floor_building = @floor_building,
    manager_doctor_amka = NULLIF(@manager_doctor_amka, '');

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/doctor_department.csv'
INTO TABLE doctor_department
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(doctor_amka, department_id);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/nurse.csv'
INTO TABLE nurse
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(amka, nurse_rank, department_id);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/administrative_staff.csv'
INTO TABLE administrative_staff
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(amka, admin_role, office_work, department_id);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/bed.csv'
INTO TABLE bed
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(bed_id, department_id, bed_number, bed_type, bed_status);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/operating_place.csv'
INTO TABLE operating_place
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(place_id, place_name, place_type, place_status);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/patient.csv'
INTO TABLE patient
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@patient_amka, @first_name, @last_name, @father_name, @age, @gender, @weight_kg, @height_cm, @address_line, @phone_number, @email, @profession, @nationality, @insurance_provider)
SET
    patient_amka = @patient_amka,
    first_name = @first_name,
    last_name = @last_name,
    father_name = @father_name,
    age = @age,
    gender = @gender,
    weight_kg = NULLIF(@weight_kg, ''),
    height_cm = NULLIF(@height_cm, ''),
    address_line = @address_line,
    phone_number = @phone_number,
    email = NULLIF(@email, ''),
    profession = NULLIF(@profession, ''),
    nationality = NULLIF(@nationality, ''),
    insurance_provider = @insurance_provider;

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/emergency_contact.csv'
INTO TABLE emergency_contact
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@patient_amka, @first_name, @last_name, @phone_number, @email)
SET
    patient_amka = @patient_amka,
    first_name = @first_name,
    last_name = @last_name,
    phone_number = @phone_number,
    email = NULLIF(@email, '');

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/department_shift.csv'
INTO TABLE department_shift
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(shift_id, department_id, shift_date, shift_type, start_time, end_time);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/shift_assignment.csv'
INTO TABLE shift_assignment
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@shift_id, @personnel_amka, @assigned_role)
SET
    shift_id = @shift_id,
    personnel_amka = @personnel_amka,
    assigned_role = NULLIF(@assigned_role, '');

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/emergency_visit.csv'
INTO TABLE emergency_visit
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@visit_id, @patient_amka, @triage_nurse_amka, @arrival_ts, @symptoms, @emergency_level, @service_start_ts, @disposition, @discharge_instructions, @referred_department_id)
SET
    visit_id = @visit_id,
    patient_amka = @patient_amka,
    triage_nurse_amka = @triage_nurse_amka,
    arrival_ts = @arrival_ts,
    symptoms = @symptoms,
    emergency_level = @emergency_level,
    service_start_ts = NULLIF(@service_start_ts, ''),
    service_end_ts = NULL,
    disposition = @disposition,
    referred_department_id = NULLIF(@referred_department_id, ''),
    discharge_instructions = NULLIF(@discharge_instructions, '');

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/hospitalization.csv'
INTO TABLE hospitalization
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@hosp_id, @patient_amka, @department_id, @bed_id, @ken_code, @admission_ts, @discharge_ts, @admission_icd10_code, @discharge_icd10_code, @total_cost)
SET
    hosp_id = @hosp_id,
    patient_amka = @patient_amka,
    department_id = @department_id,
    bed_id = @bed_id,
    emergency_visit_id = NULL,
    ken_code = @ken_code,
    admission_ts = @admission_ts,
    discharge_ts = NULLIF(@discharge_ts, ''),
    admission_icd10_code = @admission_icd10_code,
    discharge_icd10_code = NULLIF(@discharge_icd10_code, ''),
    total_cost = @total_cost;

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/hospitalization_doctor.csv'
INTO TABLE hospitalization_doctor
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(hosp_id, doctor_amka, doctor_role, is_primary);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/lab_test.csv'
INTO TABLE lab_test
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@test_id, @hosp_id, @test_code, @ordered_by_doctor_amka, @test_datetime, @result_text)
SET
    test_id = @test_id,
    hosp_id = @hosp_id,
    test_code = @test_code,
    ordered_by_doctor_amka = @ordered_by_doctor_amka,
    test_datetime = @test_datetime,
    result_text = NULLIF(@result_text, ''),
    result_numeric = NULL,
    result_unit = NULL,
    cost = 0;

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/procedure_event.csv'
INTO TABLE procedure_event
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(procedure_event_id, hosp_id, procedure_code, place_id, chief_surgeon_amka, start_ts, end_ts, actual_duration_min);

DROP TEMPORARY TABLE IF EXISTS tmp_procedure_participant_load;
DROP TEMPORARY TABLE IF EXISTS tmp_procedure_participant_compare;
CREATE TEMPORARY TABLE tmp_procedure_participant_load (
    procedure_event_id BIGINT NOT NULL,
    personnel_amka CHAR(11) NOT NULL,
    participant_role VARCHAR(40) NOT NULL
);
CREATE TEMPORARY TABLE tmp_procedure_participant_compare LIKE tmp_procedure_participant_load;

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/procedure_participant.csv'
INTO TABLE tmp_procedure_participant_load
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(procedure_event_id, personnel_amka, participant_role);

INSERT INTO tmp_procedure_participant_compare
SELECT *
FROM tmp_procedure_participant_load;

INSERT INTO procedure_participant (procedure_event_id, personnel_amka, participant_role)
SELECT DISTINCT
    t.procedure_event_id,
    t.personnel_amka,
    t.participant_role
FROM tmp_procedure_participant_load t
JOIN procedure_event target_event
  ON target_event.procedure_event_id = t.procedure_event_id
JOIN personnel p
  ON p.amka = t.personnel_amka
WHERE t.participant_role IN ('ASSISTANT_DOCTOR', 'SCRUB_NURSE')
  AND p.personnel_type <> 'ADMIN'
  AND target_event.chief_surgeon_amka <> t.personnel_amka
  AND NOT EXISTS (
      SELECT 1
      FROM procedure_event chief_event
      WHERE chief_event.chief_surgeon_amka = t.personnel_amka
        AND target_event.start_ts < chief_event.end_ts
        AND target_event.end_ts > chief_event.start_ts
  )
  AND NOT EXISTS (
      SELECT 1
      FROM tmp_procedure_participant_compare earlier
      JOIN procedure_event earlier_event
        ON earlier_event.procedure_event_id = earlier.procedure_event_id
      WHERE earlier.personnel_amka = t.personnel_amka
        AND earlier.procedure_event_id < t.procedure_event_id
        AND target_event.start_ts < earlier_event.end_ts
        AND target_event.end_ts > earlier_event.start_ts
  )
ORDER BY t.procedure_event_id, t.personnel_amka;

DROP TEMPORARY TABLE IF EXISTS tmp_procedure_participant_load;
DROP TEMPORARY TABLE IF EXISTS tmp_procedure_participant_compare;

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/patient_allergy.csv'
INTO TABLE patient_allergy
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(patient_amka, substance_id);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/prescription.csv'
INTO TABLE prescription
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@prescription_id, @hosp_id, @patient_amka, @doctor_amka, @drug_id, @dosage, @frequency, @start_datetime, @end_datetime)
SET
    prescription_id = @prescription_id,
    hosp_id = @hosp_id,
    patient_amka = @patient_amka,
    doctor_amka = @doctor_amka,
    drug_id = @drug_id,
    dosage = @dosage,
    frequency = @frequency,
    start_datetime = @start_datetime,
    end_datetime = NULLIF(@end_datetime, '');

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/hospitalization_evaluation.csv'
INTO TABLE hospitalization_evaluation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@hosp_id, @evaluation_date, @medical_care_score, @nursing_care_score, @cleanliness_score, @food_score, @overall_experience_score, @comments)
SET
    hosp_id = @hosp_id,
    evaluation_date = @evaluation_date,
    medical_care_score = @medical_care_score,
    nursing_care_score = @nursing_care_score,
    cleanliness_score = @cleanliness_score,
    food_score = @food_score,
    overall_experience_score = @overall_experience_score,
    comments = NULLIF(@comments, '');

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/image_asset.csv'
INTO TABLE image_asset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(image_id, image_url, alt_text);

LOAD DATA LOCAL INFILE '/Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data/hospital_dataset_bundle/data/generated/entity_image.csv'
INTO TABLE entity_image
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@entity_name, @entity_pk, @image_id, @entity_description)
SET
    entity_name = @entity_name,
    entity_pk = @entity_pk,
    image_id = @image_id,
    entity_description = NULLIF(@entity_description, '');
