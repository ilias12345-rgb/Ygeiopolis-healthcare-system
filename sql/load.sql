-- Robust generated loader. Run from the repository root.
-- Example: mysql --local-infile=1 -u root < sql/load.sql
-- Important: LOAD DATA LOCAL INFILE paths below are relative to the current
-- terminal working directory, not necessarily to this SQL file's location.
-- Therefore run the command from the repository root where data/ exists.
-- Each LOAD DATA block trims a possible trailing '\r' from the final CSV
-- field so the same loader works with both LF and accidental Windows CRLF CSVs.
USE yg_eupolis_hospital;
SET FOREIGN_KEY_CHECKS = 1;

LOAD DATA LOCAL INFILE 'data/reference/icd10_diagnosis.csv'
INTO TABLE icd10_diagnosis
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@icd10_code, @icd10_description)
SET
    icd10_code = @icd10_code,
    icd10_description = TRIM(TRAILING '\r' FROM @icd10_description);

LOAD DATA LOCAL INFILE 'data/reference/ken.csv'
INTO TABLE ken
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@ken_code, @ken_description, @basic_cost, @mean_duration_days, @extra_daily_cost)
SET
    ken_code = @ken_code,
    ken_description = @ken_description,
    basic_cost = @basic_cost,
    mean_duration_days = @mean_duration_days,
    extra_daily_cost = TRIM(TRAILING '\r' FROM @extra_daily_cost);

LOAD DATA LOCAL INFILE 'data/reference/procedure_catalog.csv'
INTO TABLE procedure_catalog
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@procedure_code, @procedure_name, @procedure_category, @required_place_type)
SET
    procedure_code = @procedure_code,
    procedure_name = @procedure_name,
    procedure_category = @procedure_category,
    required_place_type = TRIM(TRAILING '\r' FROM @required_place_type);

LOAD DATA LOCAL INFILE 'data/reference/lab_test_catalog.csv'
INTO TABLE lab_test_catalog
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@test_code, @test_name, @test_type)
SET
    test_code = @test_code,
    test_name = @test_name,
    test_type = TRIM(TRAILING '\r' FROM @test_type);

LOAD DATA LOCAL INFILE 'data/reference/drug.csv'
INTO TABLE drug
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@drug_id, @drug_name)
SET
    drug_id = @drug_id,
    drug_name = TRIM(TRAILING '\r' FROM @drug_name);

LOAD DATA LOCAL INFILE 'data/reference/active_substance.csv'
INTO TABLE active_substance
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@substance_id, @substance_name)
SET
    substance_id = @substance_id,
    substance_name = TRIM(TRAILING '\r' FROM @substance_name);

LOAD DATA LOCAL INFILE 'data/reference/drug_active_substance.csv'
INTO TABLE drug_active_substance
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@drug_id, @substance_id)
SET
    drug_id = @drug_id,
    substance_id = TRIM(TRAILING '\r' FROM @substance_id);

LOAD DATA LOCAL INFILE 'data/generated/personnel.csv'
INTO TABLE personnel
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@amka, @first_name, @last_name, @age, @email, @phone_number, @hiring_date, @personnel_type)
SET
    amka = @amka,
    first_name = @first_name,
    last_name = @last_name,
    age = @age,
    email = @email,
    phone_number = @phone_number,
    hiring_date = @hiring_date,
    personnel_type = TRIM(TRAILING '\r' FROM @personnel_type);

LOAD DATA LOCAL INFILE 'data/generated/doctor.csv'
INTO TABLE doctor
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@amka, @license_number, @specialization, @doctor_rank, @supervisor_amka)
SET
    amka = TRIM(TRAILING '\r' FROM @amka),
    license_number = TRIM(TRAILING '\r' FROM @license_number),
    specialization = TRIM(TRAILING '\r' FROM @specialization),
    doctor_rank = TRIM(TRAILING '\r' FROM @doctor_rank),
    supervisor_amka = NULLIF(TRIM(TRAILING '\r' FROM @supervisor_amka), '');

LOAD DATA LOCAL INFILE 'data/generated/department.csv'
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
    manager_doctor_amka = NULLIF(TRIM(TRAILING '\r' FROM @manager_doctor_amka), '');

LOAD DATA LOCAL INFILE 'data/generated/doctor_department.csv'
INTO TABLE doctor_department
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@doctor_amka, @department_id)
SET
    doctor_amka = @doctor_amka,
    department_id = TRIM(TRAILING '\r' FROM @department_id);

LOAD DATA LOCAL INFILE 'data/generated/nurse.csv'
INTO TABLE nurse
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@amka, @nurse_rank, @department_id)
SET
    amka = @amka,
    nurse_rank = @nurse_rank,
    department_id = TRIM(TRAILING '\r' FROM @department_id);

LOAD DATA LOCAL INFILE 'data/generated/administrative_staff.csv'
INTO TABLE administrative_staff
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@amka, @admin_role, @office_work, @department_id)
SET
    amka = @amka,
    admin_role = @admin_role,
    office_work = @office_work,
    department_id = TRIM(TRAILING '\r' FROM @department_id);

LOAD DATA LOCAL INFILE 'data/generated/bed.csv'
INTO TABLE bed
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@bed_id, @department_id, @bed_type, @bed_status)
SET
    bed_id = @bed_id,
    department_id = @department_id,
    bed_type = @bed_type,
    bed_status = TRIM(TRAILING '\r' FROM @bed_status);

LOAD DATA LOCAL INFILE 'data/generated/operating_place.csv'
INTO TABLE operating_place
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@place_id, @place_name, @place_type, @place_status)
SET
    place_id = @place_id,
    place_name = @place_name,
    place_type = @place_type,
    place_status = TRIM(TRAILING '\r' FROM @place_status);

LOAD DATA LOCAL INFILE 'data/generated/patient.csv'
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
    insurance_provider = TRIM(TRAILING '\r' FROM @insurance_provider);

LOAD DATA LOCAL INFILE 'data/generated/emergency_contact.csv'
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
    email = NULLIF(TRIM(TRAILING '\r' FROM @email), '');

LOAD DATA LOCAL INFILE 'data/generated/department_shift.csv'
INTO TABLE department_shift
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@shift_id, @department_id, @shift_date, @shift_type, @start_time, @end_time, @shift_status)
SET
    shift_id = @shift_id,
    department_id = @department_id,
    shift_date = @shift_date,
    shift_type = @shift_type,
    start_time = @start_time,
    end_time = @end_time,
    shift_status = TRIM(TRAILING '\r' FROM @shift_status);

LOAD DATA LOCAL INFILE 'data/generated/shift_assignment.csv'
INTO TABLE shift_assignment
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@shift_id, @personnel_amka, @assigned_role)
SET
    shift_id = @shift_id,
    personnel_amka = @personnel_amka,
    assigned_role = NULLIF(TRIM(TRAILING '\r' FROM @assigned_role), '');

-- Mark shifts as valid only after all staff assignments have loaded.
-- This activates the vol2 shift-composition and resident-supervisor checks.
UPDATE department_shift
SET shift_status = 'VALID'
WHERE shift_status = 'PROCESSING';

LOAD DATA LOCAL INFILE 'data/generated/emergency_visit.csv'
INTO TABLE emergency_visit
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@visit_id, @patient_amka, @triage_nurse_amka, @arrival_ts, @symptoms, @emergency_level, @service_start_ts, @disposition, @referred_department_id, @discharge_instructions, @status)
SET
    visit_id = @visit_id,
    patient_amka = @patient_amka,
    triage_nurse_amka = @triage_nurse_amka,
    arrival_ts = @arrival_ts,
    symptoms = @symptoms,
    emergency_level = @emergency_level,
    service_start_ts = NULLIF(@service_start_ts, ''),
    disposition = @disposition,
    referred_department_id = NULLIF(@referred_department_id, ''),
    discharge_instructions = NULLIF(@discharge_instructions, ''),
    status = NULLIF(TRIM(TRAILING '\r' FROM @status), '');

LOAD DATA LOCAL INFILE 'data/generated/hospitalization.csv'
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
    ken_code = @ken_code,
    admission_ts = @admission_ts,
    discharge_ts = NULLIF(@discharge_ts, ''),
    admission_icd10_code = @admission_icd10_code,
    discharge_icd10_code = NULLIF(@discharge_icd10_code, ''),
    total_cost = TRIM(TRAILING '\r' FROM @total_cost);

LOAD DATA LOCAL INFILE 'data/generated/hospitalization_doctor.csv'
INTO TABLE hospitalization_doctor
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@hosp_id, @doctor_amka)
SET
    hosp_id = @hosp_id,
    doctor_amka = TRIM(TRAILING '\r' FROM @doctor_amka);

LOAD DATA LOCAL INFILE 'data/generated/lab_test.csv'
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
    result_text = NULLIF(TRIM(TRAILING '\r' FROM @result_text), '');

LOAD DATA LOCAL INFILE 'data/generated/procedure_event.csv'
INTO TABLE procedure_event
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@procedure_event_id, @hosp_id, @procedure_code, @place_id, @chief_surgeon_amka, @start_ts, @end_ts, @actual_duration_min)
SET
    procedure_event_id = @procedure_event_id,
    hosp_id = @hosp_id,
    procedure_code = @procedure_code,
    place_id = @place_id,
    chief_surgeon_amka = @chief_surgeon_amka,
    start_ts = @start_ts,
    end_ts = @end_ts,
    actual_duration_min = TRIM(TRAILING '\r' FROM @actual_duration_min);

LOAD DATA LOCAL INFILE 'data/generated/procedure_participant.csv'
INTO TABLE procedure_participant
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@procedure_event_id, @personnel_amka)
SET
    procedure_event_id = @procedure_event_id,
    personnel_amka = TRIM(TRAILING '\r' FROM @personnel_amka);

LOAD DATA LOCAL INFILE 'data/generated/patient_allergy.csv'
INTO TABLE patient_allergy
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@patient_amka, @substance_id)
SET
    patient_amka = @patient_amka,
    substance_id = TRIM(TRAILING '\r' FROM @substance_id);

LOAD DATA LOCAL INFILE 'data/generated/prescription.csv'
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
    end_datetime = NULLIF(TRIM(TRAILING '\r' FROM @end_datetime), '');

LOAD DATA LOCAL INFILE 'data/generated/hospitalization_evaluation.csv'
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
    comments = NULLIF(TRIM(TRAILING '\r' FROM @comments), '');

LOAD DATA LOCAL INFILE 'data/generated/image_asset.csv'
INTO TABLE image_asset
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@image_id, @image_url, @alt_text)
SET
    image_id = @image_id,
    image_url = @image_url,
    alt_text = TRIM(TRAILING '\r' FROM @alt_text);

LOAD DATA LOCAL INFILE 'data/generated/entity_image.csv'
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
    entity_description = NULLIF(TRIM(TRAILING '\r' FROM @entity_description), '');
