DROP DATABASE IF EXISTS yg_eupolis_hospital;
CREATE DATABASE yg_eupolis_hospital
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE yg_eupolis_hospital;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS entity_image;
DROP TABLE IF EXISTS image_asset;
DROP TABLE IF EXISTS hospitalization_evaluation;
DROP TABLE IF EXISTS prescription;
DROP TABLE IF EXISTS patient_allergy;
DROP TABLE IF EXISTS drug_active_substance;
DROP TABLE IF EXISTS active_substance;
DROP TABLE IF EXISTS drug;
DROP TABLE IF EXISTS procedure_participant;
DROP TABLE IF EXISTS procedure_event;
DROP TABLE IF EXISTS procedure_catalog;
DROP TABLE IF EXISTS lab_test;
DROP TABLE IF EXISTS lab_test_catalog;
DROP TABLE IF EXISTS hospitalization_doctor;
DROP TABLE IF EXISTS hospitalization;
DROP TABLE IF EXISTS emergency_visit;
DROP TABLE IF EXISTS shift_assignment;
DROP TABLE IF EXISTS department_shift;
DROP TABLE IF EXISTS operating_place;
DROP TABLE IF EXISTS icd10_ken_map;
DROP TABLE IF EXISTS ken;
DROP TABLE IF EXISTS icd10_diagnosis;
DROP TABLE IF EXISTS emergency_contact;
DROP TABLE IF EXISTS bed;
DROP TABLE IF EXISTS doctor_department;
DROP TABLE IF EXISTS administrative_staff;
DROP TABLE IF EXISTS nurse;
DROP TABLE IF EXISTS doctor;
DROP TABLE IF EXISTS patient;
DROP TABLE IF EXISTS department;
DROP TABLE IF EXISTS personnel;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE personnel (
    amka                    CHAR(11) PRIMARY KEY,
    first_name              VARCHAR(80) NOT NULL,
    last_name               VARCHAR(80) NOT NULL,
    age                     INT NOT NULL,
    email                   VARCHAR(255) NOT NULL,
    phone_number            VARCHAR(30) NOT NULL,
    hiring_date             DATE NOT NULL,
    personnel_type          VARCHAR(20) NOT NULL,
    CONSTRAINT uq_personnel_email UNIQUE (email),
    CONSTRAINT ck_personnel_age CHECK (age BETWEEN 18 AND 100),
    CONSTRAINT ck_personnel_type CHECK (personnel_type IN ('DOCTOR', 'NURSE', 'ADMIN'))
);

CREATE TABLE doctor (
    amka                    CHAR(11) PRIMARY KEY,
    license_number          VARCHAR(50) NOT NULL,
    specialization          VARCHAR(120) NOT NULL,
    doctor_rank             VARCHAR(20) NOT NULL,
    supervisor_amka         CHAR(11) NULL,
    CONSTRAINT fk_doctor_personnel
        FOREIGN KEY (amka) REFERENCES personnel(amka)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_doctor_supervisor
        FOREIGN KEY (supervisor_amka) REFERENCES doctor(amka)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT uq_doctor_license UNIQUE (license_number),
    CONSTRAINT ck_doctor_rank CHECK (doctor_rank IN ('RESIDENT', 'CONSULTANT_B', 'CONSULTANT_A', 'DIRECTOR'))
);

CREATE TABLE department (
    department_id           INT AUTO_INCREMENT PRIMARY KEY,
    department_name         VARCHAR(120) NOT NULL,
    description             TEXT NULL,
    bed_capacity            INT NOT NULL,
    floor_building          VARCHAR(120) NOT NULL,
    manager_doctor_amka     CHAR(11) NULL,
    CONSTRAINT uq_department_name UNIQUE (department_name),
    CONSTRAINT ck_department_bed_capacity CHECK (bed_capacity >= 0),
    CONSTRAINT fk_department_manager
    FOREIGN KEY (manager_doctor_amka) REFERENCES doctor(amka)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
    CONSTRAINT uq_department_manager UNIQUE (manager_doctor_amka)
);

CREATE TABLE nurse (
    amka                    CHAR(11) PRIMARY KEY,
    nurse_rank              VARCHAR(20) NOT NULL,
    department_id           INT NOT NULL,
    CONSTRAINT fk_nurse_personnel
        FOREIGN KEY (amka) REFERENCES personnel(amka)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_nurse_department
        FOREIGN KEY (department_id) REFERENCES department(department_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT ck_nurse_rank CHECK (nurse_rank IN ('ASSISTANT_NURSE', 'NURSE', 'HEAD_NURSE'))
);

CREATE TABLE administrative_staff (
    amka                    CHAR(11) PRIMARY KEY,
    admin_role              VARCHAR(120) NOT NULL,
    office_work             VARCHAR(120) NOT NULL,
    department_id           INT NOT NULL,
    CONSTRAINT fk_admin_personnel
        FOREIGN KEY (amka) REFERENCES personnel(amka)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_admin_department
        FOREIGN KEY (department_id) REFERENCES department(department_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


CREATE TABLE doctor_department (
    doctor_amka             CHAR(11) NOT NULL,
    department_id           INT NOT NULL,
    PRIMARY KEY (doctor_amka, department_id),
    CONSTRAINT fk_doctor_department_doctor
        FOREIGN KEY (doctor_amka) REFERENCES doctor(amka)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_doctor_department_department
        FOREIGN KEY (department_id) REFERENCES department(department_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE bed (
    bed_id                   INT AUTO_INCREMENT PRIMARY KEY,
    department_id            INT NOT NULL,
    bed_number               INT NOT NULL,
    bed_type                 VARCHAR(20) NOT NULL,
    bed_status               VARCHAR(20) NOT NULL,
    CONSTRAINT fk_bed_department
        FOREIGN KEY (department_id) REFERENCES department(department_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT uq_bed_department_number UNIQUE (department_id, bed_number),
    CONSTRAINT ck_bed_number CHECK (bed_number > 0),
    CONSTRAINT ck_bed_type CHECK (bed_type IN ('ICU', 'SINGLE', 'MULTI_BED')),
    CONSTRAINT ck_bed_status CHECK (bed_status IN ('AVAILABLE', 'OCCUPIED', 'MAINTENANCE'))
) ENGINE=InnoDB;

CREATE TABLE patient (
    patient_amka            CHAR(11) PRIMARY KEY,
    first_name              VARCHAR(80) NOT NULL,
    last_name               VARCHAR(80) NOT NULL,
    father_name             VARCHAR(80) NOT NULL,
    age                     INT NOT NULL,
    gender                  VARCHAR(20) NOT NULL,
    weight_kg               DECIMAL(5,2) NULL,
    height_cm               DECIMAL(5,2) NULL,
    address_line            VARCHAR(255) NOT NULL,
    phone_number            VARCHAR(30) NOT NULL,
    email                   VARCHAR(255) NULL,
    profession              VARCHAR(120) NULL,
    nationality             VARCHAR(80) NULL,
    insurance_provider      VARCHAR(120) NOT NULL,
    CONSTRAINT uq_patient_email UNIQUE (email),
    CONSTRAINT ck_patient_age CHECK (age BETWEEN 0 AND 120),
    CONSTRAINT ck_patient_weight CHECK (weight_kg IS NULL OR weight_kg > 0),
    CONSTRAINT ck_patient_height CHECK (height_cm IS NULL OR height_cm > 0)
);

CREATE TABLE emergency_contact (
    patient_amka            CHAR(11) NOT NULL,
    first_name              VARCHAR(80) NOT NULL,
    last_name               VARCHAR(80) NOT NULL,
    phone_number            VARCHAR(30) NOT NULL,
    email                   VARCHAR(255) NULL,
    PRIMARY KEY (patient_amka, first_name, last_name, phone_number),
    CONSTRAINT fk_emergency_contact_patient
        FOREIGN KEY (patient_amka) REFERENCES patient(patient_amka)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE icd10_diagnosis (
    icd10_code              VARCHAR(20) PRIMARY KEY,
    icd10_description       VARCHAR(500) NOT NULL
);

CREATE TABLE ken (
    ken_code                VARCHAR(20) PRIMARY KEY,
    ken_description         VARCHAR(500) NOT NULL,
    basic_cost              DECIMAL(12,2) NOT NULL,
    mean_duration_days      INT NOT NULL,
    extra_daily_cost        DECIMAL(12,2) NOT NULL,/*numeric*/
    CONSTRAINT ck_ken_costs CHECK (basic_cost >= 0 AND extra_daily_cost >= 0),
    CONSTRAINT ck_ken_duration CHECK (mean_duration_days >= 0)
);

CREATE TABLE icd10_ken_map (
    mdc_code                VARCHAR(20) NOT NULL,
    ken_code                VARCHAR(20) NOT NULL,
    icd10_code_prefix       VARCHAR(20) NOT NULL,
    PRIMARY KEY (ken_code, icd10_code_prefix),
    CONSTRAINT fk_icd10_ken_map_ken
        FOREIGN KEY (ken_code) REFERENCES ken(ken_code)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE operating_place (
    place_id                INT AUTO_INCREMENT PRIMARY KEY,
    place_name              VARCHAR(120) NOT NULL,
    place_type              VARCHAR(30) NOT NULL,
    place_status            VARCHAR(20) NOT NULL,
    CONSTRAINT uq_place_name UNIQUE (place_name),
    CONSTRAINT ck_place_type CHECK (place_type IN ('OPERATING_ROOM', 'PROCEDURE_ROOM')),
    CONSTRAINT ck_place_status CHECK (place_status IN ('AVAILABLE', 'OCCUPIED', 'MAINTENANCE'))
);

CREATE TABLE department_shift (
    shift_id                BIGINT AUTO_INCREMENT PRIMARY KEY,
    department_id           INT NOT NULL,
    shift_date              DATE NOT NULL,
    shift_type              VARCHAR(20) NOT NULL,
    start_time              TIME NOT NULL,
    end_time                TIME NOT NULL,
    CONSTRAINT fk_department_shift_department
        FOREIGN KEY (department_id) REFERENCES department(department_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT uq_department_shift UNIQUE (department_id, shift_date, shift_type),
    CONSTRAINT ck_shift_type CHECK (shift_type IN ('MORNING', 'AFTERNOON', 'NIGHT')),
    CONSTRAINT ck_shift_time CHECK (
        (shift_type = 'MORNING'   AND start_time = '07:00:00' AND end_time = '15:00:00') OR
        (shift_type = 'AFTERNOON' AND start_time = '15:00:00' AND end_time = '23:00:00') OR
        (shift_type = 'NIGHT'     AND start_time = '23:00:00' AND end_time = '07:00:00')
    )
);

CREATE TABLE shift_assignment (
    shift_id                BIGINT NOT NULL,
    personnel_amka          CHAR(11) NOT NULL,
    assigned_role           VARCHAR(40) NULL,
    PRIMARY KEY (shift_id, personnel_amka),
    CONSTRAINT fk_shift_assignment_shift
        FOREIGN KEY (shift_id) REFERENCES department_shift(shift_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_shift_assignment_personnel
        FOREIGN KEY (personnel_amka) REFERENCES personnel(amka)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE emergency_visit (
    visit_id                BIGINT AUTO_INCREMENT PRIMARY KEY,
    patient_amka            CHAR(11) NOT NULL,
    triage_nurse_amka       CHAR(11) NOT NULL,
    arrival_ts              DATETIME NOT NULL,
    symptoms                TEXT NOT NULL,
    emergency_level         INT NOT NULL,
    referred_department_id  INT NULL,
    service_start_ts        DATETIME NULL,
    service_end_ts          DATETIME NULL,
    disposition             VARCHAR(20) NOT NULL,
    discharge_instructions  TEXT NULL,
    CONSTRAINT fk_emergency_visit_patient
        FOREIGN KEY (patient_amka) REFERENCES patient(patient_amka)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_emergency_visit_triage_nurse
        FOREIGN KEY (triage_nurse_amka) REFERENCES nurse(amka)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_emergency_visit_referred_department
        FOREIGN KEY (referred_department_id) REFERENCES department(department_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT ck_emergency_level CHECK (emergency_level BETWEEN 1 AND 5),
    CONSTRAINT ck_emergency_disposition CHECK (disposition IN ('DISCHARGED', 'HOSPITALIZED')),
    CONSTRAINT ck_emergency_times CHECK (
        (service_start_ts IS NULL OR service_start_ts >= arrival_ts)
        AND (service_end_ts IS NULL OR service_start_ts IS NULL OR service_end_ts >= service_start_ts)
    )
);

CREATE TABLE hospitalization (
    hosp_id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    patient_amka             CHAR(11) NOT NULL,
    department_id            INT NOT NULL,
    bed_id                   INT NOT NULL,
    emergency_visit_id       BIGINT NULL,
    ken_code                 VARCHAR(20) NOT NULL,
    admission_ts             DATETIME NOT NULL,
    discharge_ts             DATETIME NULL,
    admission_icd10_code     VARCHAR(20) NOT NULL,
    discharge_icd10_code     VARCHAR(20) NULL,
    total_cost               DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_hosp_patient
        FOREIGN KEY (patient_amka) REFERENCES patient(patient_amka)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_hosp_department
        FOREIGN KEY (department_id) REFERENCES department(department_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_hosp_bed
        FOREIGN KEY (bed_id) REFERENCES bed(bed_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_hosp_emergency_visit
        FOREIGN KEY (emergency_visit_id) REFERENCES emergency_visit(visit_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CONSTRAINT fk_hosp_ken
        FOREIGN KEY (ken_code) REFERENCES ken(ken_code)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_hosp_admission_icd10
        FOREIGN KEY (admission_icd10_code) REFERENCES icd10_diagnosis(icd10_code)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_hosp_discharge_icd10
        FOREIGN KEY (discharge_icd10_code) REFERENCES icd10_diagnosis(icd10_code)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT uq_hosp_patient_pair UNIQUE (hosp_id, patient_amka),
    CONSTRAINT ck_hosp_cost CHECK (total_cost >= 0),
    CONSTRAINT ck_hosp_dates CHECK (discharge_ts IS NULL OR discharge_ts >= admission_ts)
);

CREATE TABLE hospitalization_doctor (
    hosp_id                  BIGINT NOT NULL,
    doctor_amka              CHAR(11) NOT NULL,
    doctor_role              VARCHAR(40) NOT NULL,
    is_primary               BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (hosp_id, doctor_amka),
    CONSTRAINT fk_hosp_doctor_hosp
        FOREIGN KEY (hosp_id) REFERENCES hospitalization(hosp_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_hosp_doctor_doctor
        FOREIGN KEY (doctor_amka) REFERENCES doctor(amka)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT ck_hosp_doctor_role CHECK (doctor_role IN ('PRIMARY', 'CONSULTING'))
);

CREATE TABLE lab_test_catalog (
    test_code               VARCHAR(30) PRIMARY KEY,
    test_name               TEXT NOT NULL,
    test_type               VARCHAR(80) NOT NULL
);

CREATE TABLE lab_test (
    test_id                 BIGINT AUTO_INCREMENT PRIMARY KEY,
    hosp_id                 BIGINT NOT NULL,
    test_code               VARCHAR(30) NOT NULL,
    ordered_by_doctor_amka  CHAR(11) NOT NULL,
    test_datetime           DATETIME NOT NULL,
    result_text             TEXT NULL,
    result_numeric          DECIMAL(12,2) NULL,
    result_unit             VARCHAR(40) NULL,
    cost                    DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_lab_test_hosp
        FOREIGN KEY (hosp_id) REFERENCES hospitalization(hosp_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_lab_test_catalog
        FOREIGN KEY (test_code) REFERENCES lab_test_catalog(test_code)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_lab_test_doctor
        FOREIGN KEY (ordered_by_doctor_amka) REFERENCES doctor(amka)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT ck_lab_test_cost CHECK (cost >= 0)
);

CREATE TABLE procedure_catalog (
    procedure_code          VARCHAR(30) PRIMARY KEY,
    procedure_name          TEXT NOT NULL,
    procedure_category      VARCHAR(20) NOT NULL,
    required_place_type     VARCHAR(30) NOT NULL,
    CONSTRAINT ck_procedure_category CHECK (procedure_category IN ('SURGICAL', 'DIAGNOSTIC', 'THERAPEUTIC')),
    CONSTRAINT ck_required_place_type CHECK (required_place_type IN ('OPERATING_ROOM', 'PROCEDURE_ROOM'))
);

CREATE TABLE procedure_event (
    procedure_event_id      BIGINT AUTO_INCREMENT PRIMARY KEY,
    hosp_id                 BIGINT NOT NULL,
    procedure_code          VARCHAR(30) NOT NULL,
    place_id                INT NOT NULL,
    chief_surgeon_amka      CHAR(11) NOT NULL,
    start_ts                DATETIME NOT NULL,
    end_ts                  DATETIME NOT NULL,
    actual_duration_min     INT NOT NULL,
    CONSTRAINT fk_proc_event_hosp
        FOREIGN KEY (hosp_id) REFERENCES hospitalization(hosp_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_proc_event_catalog
        FOREIGN KEY (procedure_code) REFERENCES procedure_catalog(procedure_code)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_proc_event_place
        FOREIGN KEY (place_id) REFERENCES operating_place(place_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_proc_event_chief
        FOREIGN KEY (chief_surgeon_amka) REFERENCES doctor(amka)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT ck_proc_event_times CHECK (end_ts > start_ts),
    CONSTRAINT ck_proc_event_duration CHECK (actual_duration_min > 0)
);

CREATE TABLE procedure_participant (
    procedure_event_id      BIGINT NOT NULL,
    personnel_amka          CHAR(11) NOT NULL,
    participant_role        VARCHAR(40) NOT NULL,
    PRIMARY KEY (procedure_event_id, personnel_amka),
    CONSTRAINT fk_proc_participant_event
        FOREIGN KEY (procedure_event_id) REFERENCES procedure_event(procedure_event_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_proc_participant_personnel
        FOREIGN KEY (personnel_amka) REFERENCES personnel(amka)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT ck_proc_participant_role CHECK (participant_role IN ('ASSISTANT_DOCTOR', 'SCRUB_NURSE'))
);

CREATE TABLE drug (
    drug_id                 VARCHAR(80) PRIMARY KEY,
    drug_name               VARCHAR(255) NOT NULL
);

CREATE TABLE active_substance (
    substance_id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    substance_name          VARCHAR(255) NOT NULL,
    CONSTRAINT uq_substance_name UNIQUE (substance_name)
);

CREATE TABLE drug_active_substance (
    drug_id                 VARCHAR(80) NOT NULL,
    substance_id            BIGINT NOT NULL,
    PRIMARY KEY (drug_id, substance_id),
    CONSTRAINT fk_das_drug
        FOREIGN KEY (drug_id) REFERENCES drug(drug_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_das_substance
        FOREIGN KEY (substance_id) REFERENCES active_substance(substance_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE patient_allergy (
    patient_amka            CHAR(11) NOT NULL,
    substance_id            BIGINT NOT NULL,
    PRIMARY KEY (patient_amka, substance_id),
    CONSTRAINT fk_patient_allergy_patient
        FOREIGN KEY (patient_amka) REFERENCES patient(patient_amka)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_patient_allergy_substance
        FOREIGN KEY (substance_id) REFERENCES active_substance(substance_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE prescription (
    prescription_id         BIGINT AUTO_INCREMENT PRIMARY KEY,
    hosp_id                 BIGINT NOT NULL,
    patient_amka            CHAR(11) NOT NULL,
    doctor_amka             CHAR(11) NOT NULL,
    drug_id                 VARCHAR(80) NOT NULL,
    dosage                  VARCHAR(120) NOT NULL,
    frequency               VARCHAR(120) NOT NULL,
    start_datetime          DATETIME NOT NULL,
    end_datetime            DATETIME NULL,
    CONSTRAINT fk_prescription_hosp_patient
        FOREIGN KEY (hosp_id, patient_amka) REFERENCES hospitalization(hosp_id, patient_amka)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_prescription_doctor
        FOREIGN KEY (doctor_amka) REFERENCES doctor(amka)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_prescription_drug
        FOREIGN KEY (drug_id) REFERENCES drug(drug_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT uq_prescription UNIQUE (doctor_amka, patient_amka, drug_id, start_datetime),
    CONSTRAINT ck_prescription_dates CHECK (end_datetime IS NULL OR end_datetime >= start_datetime)
);

CREATE TABLE hospitalization_evaluation (
    hosp_id                         BIGINT PRIMARY KEY,
    evaluation_date                DATE NOT NULL,
    medical_care_score             INT NOT NULL,
    nursing_care_score             INT NOT NULL,
    cleanliness_score              INT NOT NULL,
    food_score                     INT NOT NULL,
    overall_experience_score       INT NOT NULL,
    comments                       TEXT NULL,
    CONSTRAINT fk_eval_hosp
        FOREIGN KEY (hosp_id) REFERENCES hospitalization(hosp_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT ck_eval_medical CHECK (medical_care_score BETWEEN 1 AND 5),
    CONSTRAINT ck_eval_nursing CHECK (nursing_care_score BETWEEN 1 AND 5),
    CONSTRAINT ck_eval_cleanliness CHECK (cleanliness_score BETWEEN 1 AND 5),
    CONSTRAINT ck_eval_food CHECK (food_score BETWEEN 1 AND 5),
    CONSTRAINT ck_eval_overall CHECK (overall_experience_score BETWEEN 1 AND 5)
);

CREATE TABLE image_asset (
    image_id                 BIGINT AUTO_INCREMENT PRIMARY KEY,
    image_url                VARCHAR(500) NOT NULL,
    alt_text                 VARCHAR(500) NOT NULL
);

CREATE TABLE entity_image (
    entity_name              VARCHAR(64) NOT NULL,
    entity_pk                VARCHAR(64) NOT NULL,
    image_id                 BIGINT NOT NULL,
    entity_description       TEXT NULL,
    PRIMARY KEY (entity_name, entity_pk, image_id),
    CONSTRAINT fk_entity_image_asset
        FOREIGN KEY (image_id) REFERENCES image_asset(image_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

/* ---------------------------------------------------------------------------
   Query-support indexes.
   These indexes support the exercise queries, reporting views, and trigger
   lookups. Final pruning should be done after sql/queries.sql is complete and
   every query has been checked with EXPLAIN.
--------------------------------------------------------------------------- */

/* Q2: helps filter doctors by specialization and rank. */
CREATE INDEX idx_doctor_specialization_rank
    ON doctor (specialization, doctor_rank);

/* Q13: helps follow the doctor supervision hierarchy. */
CREATE INDEX idx_doctor_supervisor
    ON doctor (supervisor_amka);

/* Q8, Q12: helps find nurses in a department by rank. */
CREATE INDEX idx_nurse_department_rank
    ON nurse (department_id, nurse_rank);

/* Q8, Q12: helps find administrative staff in a department by role. */
CREATE INDEX idx_admin_department_role
    ON administrative_staff (department_id, admin_role);

/* Q12: helps list doctors assigned to a department. */
CREATE INDEX idx_doctor_department_department
    ON doctor_department (department_id, doctor_amka);

/* Q8, Q12: helps find department shifts by date and shift type. */
CREATE INDEX idx_shift_department_date_type
    ON department_shift (department_id, shift_date, shift_type);

/* Q8, Q12: helps find shifts assigned to a specific staff member. */
CREATE INDEX idx_shift_assignment_personnel
    ON shift_assignment (personnel_amka, shift_id);

/* Q15 and FIFO queue: helps order emergency visits by severity and arrival time. */
CREATE INDEX idx_emergency_visit_level_arrival
    ON emergency_visit (emergency_level, arrival_ts);

/* Q15 and FIFO queue: helps filter emergency visits by referred department. */
CREATE INDEX idx_emergency_visit_referred_department
    ON emergency_visit (referred_department_id);

/* Q3, Q6, Q9: helps find patient hospitalizations by department and dates. */
CREATE INDEX idx_hosp_patient_dept_dates
    ON hospitalization (patient_amka, department_id, admission_ts, discharge_ts);

/* Q1: helps find hospitalizations for a department by admission date. */
CREATE INDEX idx_hosp_department_admission
    ON hospitalization (department_id, admission_ts);

/* Q1: helps find hospitalizations by KEN code. */
CREATE INDEX idx_hosp_ken
    ON hospitalization (ken_code);

/* Q14: helps group/filter hospitalizations by admission ICD-10 code. */
CREATE INDEX idx_hosp_admission_icd10
    ON hospitalization (admission_icd10_code);

/* Q14: helps match ICD-10 prefixes to KEN codes. */
CREATE INDEX idx_icd10_ken_map_prefix
    ON icd10_ken_map (icd10_code_prefix, ken_code);

/* Bed/occupancy views: helps filter beds by department, status, and type. */
CREATE INDEX idx_bed_department_status
    ON bed (department_id, bed_status, bed_type);

/* Lab reporting: helps find tests for a hospitalization by code and date. */
CREATE INDEX idx_lab_test_hosp_code
    ON lab_test (hosp_id, test_code, test_datetime);

/* Lab reporting: helps find tests ordered by a doctor over time. */
CREATE INDEX idx_lab_test_ordering_doctor
    ON lab_test (ordered_by_doctor_amka, test_datetime);

/* Procedure reporting: helps find procedures for a hospitalization by start time. */
CREATE INDEX idx_proc_event_hosp_start
    ON procedure_event (hosp_id, start_ts);

/* Q2, Q5, Q11: helps count/find procedures by chief surgeon. */
CREATE INDEX idx_proc_event_chief
    ON procedure_event (chief_surgeon_amka, start_ts);

/* Trigger support: helps detect overlapping procedures in the same place. */
CREATE INDEX idx_proc_event_place
    ON procedure_event (place_id, start_ts, end_ts);

/* Q11: helps find procedure participation by staff member. */
CREATE INDEX idx_proc_participant_personnel
    ON procedure_participant (personnel_amka, procedure_event_id);

/* Q10: helps find prescriptions for a patient during a hospitalization. */
CREATE INDEX idx_prescription_hosp_patient_start
    ON prescription (hosp_id, patient_amka, start_datetime);

/* Prescription reporting: helps find prescriptions by doctor and date. */
CREATE INDEX idx_prescription_doctor
    ON prescription (doctor_amka, start_datetime);

/* Q7: helps find drugs that contain a specific active substance. */
CREATE INDEX idx_das_substance
    ON drug_active_substance (substance_id, drug_id);

/* Q7: helps find patients allergic to a specific active substance. */
CREATE INDEX idx_patient_allergy_substance
    ON patient_allergy (substance_id, patient_amka);

/* Evaluation reporting: helps filter evaluations by date. */
CREATE INDEX idx_evaluation_date
    ON hospitalization_evaluation (evaluation_date);

/* ---------------------------------------------------------------------------
   Reporting views.
   These views keep common reporting joins in one place and make the final
   exercise queries easier to read without changing the underlying tables.
--------------------------------------------------------------------------- */

CREATE VIEW v_emergency_fifo_queue AS
SELECT
    ROW_NUMBER() OVER (
        PARTITION BY ev.referred_department_id
        ORDER BY ev.emergency_level, ev.arrival_ts, ev.visit_id
    ) AS queue_position,
    ev.visit_id,
    ev.patient_amka,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    ev.emergency_level,
    ev.arrival_ts,
    ev.referred_department_id,
    d.department_name AS referred_department_name,
    ev.symptoms
FROM emergency_visit ev
JOIN patient p ON p.patient_amka = ev.patient_amka
LEFT JOIN department d ON d.department_id = ev.referred_department_id
WHERE ev.service_start_ts IS NULL;

CREATE VIEW v_current_bed_status AS
SELECT
    d.department_id,
    d.department_name,
    b.bed_id,
    b.bed_number,
    b.bed_type,
    b.bed_status AS recorded_status,
    CASE
        WHEN h.hosp_id IS NOT NULL THEN 'OCCUPIED'
        ELSE b.bed_status
    END AS current_status,
    h.hosp_id AS current_hosp_id,
    h.patient_amka AS current_patient_amka
FROM bed b
JOIN department d ON d.department_id = b.department_id
LEFT JOIN hospitalization h
    ON h.bed_id = b.bed_id
   AND h.admission_ts <= NOW()
   AND (h.discharge_ts IS NULL OR h.discharge_ts > NOW());

CREATE VIEW v_active_hospitalizations AS
SELECT
    h.hosp_id,
    h.patient_amka,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    h.department_id,
    d.department_name,
    h.bed_id,
    b.bed_number,
    h.ken_code,
    k.ken_description,
    h.admission_ts,
    h.discharge_ts,
    h.total_cost
FROM hospitalization h
JOIN patient p ON p.patient_amka = h.patient_amka
JOIN department d ON d.department_id = h.department_id
JOIN bed b ON b.bed_id = h.bed_id
JOIN ken k ON k.ken_code = h.ken_code
WHERE h.admission_ts <= NOW()
  AND (h.discharge_ts IS NULL OR h.discharge_ts > NOW());

CREATE VIEW v_patient_history AS
SELECT
    p.patient_amka,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.age,
    p.gender,
    p.insurance_provider,
    h.hosp_id,
    d.department_name,
    h.admission_ts,
    h.discharge_ts,
    h.admission_icd10_code,
    adm.icd10_description AS admission_diagnosis,
    h.discharge_icd10_code,
    dis.icd10_description AS discharge_diagnosis,
    h.ken_code,
    k.ken_description,
    h.total_cost
FROM patient p
LEFT JOIN hospitalization h ON h.patient_amka = p.patient_amka
LEFT JOIN department d ON d.department_id = h.department_id
LEFT JOIN icd10_diagnosis adm ON adm.icd10_code = h.admission_icd10_code
LEFT JOIN icd10_diagnosis dis ON dis.icd10_code = h.discharge_icd10_code
LEFT JOIN ken k ON k.ken_code = h.ken_code;

CREATE VIEW v_doctor_workload AS
SELECT
    d.amka AS doctor_amka,
    CONCAT(p.first_name, ' ', p.last_name) AS doctor_name,
    d.specialization,
    d.doctor_rank,
    COALESCE(hc.hospitalization_count, 0) AS hospitalization_count,
    COALESCE(pc.chief_procedure_count, 0) AS chief_procedure_count,
    COALESCE(sc.shift_count, 0) AS shift_count
FROM doctor d
JOIN personnel p ON p.amka = d.amka
LEFT JOIN (
    SELECT doctor_amka, COUNT(DISTINCT hosp_id) AS hospitalization_count
    FROM hospitalization_doctor
    GROUP BY doctor_amka
) hc ON hc.doctor_amka = d.amka
LEFT JOIN (
    SELECT chief_surgeon_amka, COUNT(*) AS chief_procedure_count
    FROM procedure_event
    GROUP BY chief_surgeon_amka
) pc ON pc.chief_surgeon_amka = d.amka
LEFT JOIN (
    SELECT personnel_amka, COUNT(*) AS shift_count
    FROM shift_assignment
    GROUP BY personnel_amka
) sc ON sc.personnel_amka = d.amka;

CREATE VIEW v_department_occupancy AS
SELECT
    d.department_id,
    d.department_name,
    COUNT(b.bed_id) AS total_beds,
    SUM(CASE WHEN h.hosp_id IS NOT NULL THEN 1 ELSE 0 END) AS occupied_beds,
    SUM(CASE WHEN h.hosp_id IS NULL AND b.bed_status = 'AVAILABLE' THEN 1 ELSE 0 END) AS available_beds,
    SUM(CASE WHEN b.bed_status = 'MAINTENANCE' THEN 1 ELSE 0 END) AS maintenance_beds,
    ROUND(
        100 * SUM(CASE WHEN h.hosp_id IS NOT NULL THEN 1 ELSE 0 END) / NULLIF(COUNT(b.bed_id), 0),
        2
    ) AS occupancy_percentage
FROM department d
LEFT JOIN bed b ON b.department_id = d.department_id
LEFT JOIN hospitalization h
    ON h.bed_id = b.bed_id
   AND h.admission_ts <= NOW()
   AND (h.discharge_ts IS NULL OR h.discharge_ts > NOW())
GROUP BY d.department_id, d.department_name;

CREATE VIEW v_prescription_substances AS
SELECT
    pr.prescription_id,
    pr.hosp_id,
    pr.patient_amka,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    pr.doctor_amka,
    CONCAT(docp.first_name, ' ', docp.last_name) AS doctor_name,
    pr.drug_id,
    dr.drug_name,
    s.substance_id,
    s.substance_name,
    pr.dosage,
    pr.frequency,
    pr.start_datetime,
    pr.end_datetime
FROM prescription pr
JOIN patient p ON p.patient_amka = pr.patient_amka
JOIN personnel docp ON docp.amka = pr.doctor_amka
JOIN drug dr ON dr.drug_id = pr.drug_id
JOIN drug_active_substance das ON das.drug_id = pr.drug_id
JOIN active_substance s ON s.substance_id = das.substance_id;

CREATE VIEW v_shift_roster AS
SELECT
    ds.shift_id,
    ds.department_id,
    d.department_name,
    ds.shift_date,
    ds.shift_type,
    ds.start_time,
    ds.end_time,
    sa.personnel_amka,
    CONCAT(p.first_name, ' ', p.last_name) AS staff_name,
    p.personnel_type,
    COALESCE(doc.doctor_rank, n.nurse_rank, a.admin_role) AS staff_detail,
    sa.assigned_role
FROM department_shift ds
JOIN department d ON d.department_id = ds.department_id
JOIN shift_assignment sa ON sa.shift_id = ds.shift_id
JOIN personnel p ON p.amka = sa.personnel_amka
LEFT JOIN doctor doc ON doc.amka = p.amka
LEFT JOIN nurse n ON n.amka = p.amka
LEFT JOIN administrative_staff a ON a.amka = p.amka;


/* Triggers for key business rules */

DELIMITER $$

CREATE TRIGGER trg_doctor_supervision_bi
BEFORE INSERT ON doctor
FOR EACH ROW
BEGIN
    DECLARE current_amka CHAR(11);
    IF NEW.supervisor_amka = NEW.amka THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A doctor cannot supervise himself/herself.';
    END IF;

    IF NEW.doctor_rank = 'RESIDENT' AND NEW.supervisor_amka IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A resident doctor must have a supervisor.';
    END IF;

    IF NEW.doctor_rank = 'DIRECTOR' AND NEW.supervisor_amka IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A director doctor cannot have a supervisor.';
    END IF;

    IF NEW.supervisor_amka IS NOT NULL THEN
        SET current_amka = NEW.supervisor_amka;
        WHILE current_amka IS NOT NULL DO
            IF current_amka = NEW.amka THEN /* Cycle detected in the supervision chain. */
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Circular supervision chain detected.';
            END IF;
            SELECT supervisor_amka INTO current_amka FROM doctor WHERE amka = current_amka; /* Move one level up the chain. */
        END WHILE;
    END IF;
END$$

CREATE TRIGGER trg_doctor_supervision_bu
BEFORE UPDATE ON doctor
FOR EACH ROW
BEGIN
    DECLARE current_amka CHAR(11);
    IF NEW.supervisor_amka = NEW.amka THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A doctor cannot supervise himself/herself.';
    END IF;

    IF NEW.doctor_rank = 'RESIDENT' AND NEW.supervisor_amka IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A resident doctor must have a supervisor.';
    END IF;

    IF NEW.doctor_rank = 'DIRECTOR' AND NEW.supervisor_amka IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A director doctor cannot have a supervisor.';
    END IF;

    IF NEW.supervisor_amka IS NOT NULL THEN
        SET current_amka = NEW.supervisor_amka;
        WHILE current_amka IS NOT NULL DO
            IF current_amka = NEW.amka THEN /* Cycle detected in the supervision chain. */
                SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Circular supervision chain detected.';
            END IF;
            SELECT supervisor_amka INTO current_amka FROM doctor WHERE amka = current_amka; /* Move one level up the chain. */
        END WHILE;
    END IF;
END$$

CREATE TRIGGER trg_prescription_no_allergy_bi
BEFORE INSERT ON prescription
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM patient_allergy pa
        JOIN drug_active_substance das
          ON das.substance_id = pa.substance_id
        WHERE pa.patient_amka = NEW.patient_amka
          AND das.drug_id = NEW.drug_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Prescription forbidden: patient is allergic to an active substance of this drug.';
    END IF;
END$$

CREATE TRIGGER trg_prescription_no_allergy_bu
BEFORE UPDATE ON prescription
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM patient_allergy pa
        JOIN drug_active_substance das
          ON das.substance_id = pa.substance_id
        WHERE pa.patient_amka = NEW.patient_amka
          AND das.drug_id = NEW.drug_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Prescription forbidden: patient is allergic to an active substance of this drug.';
    END IF;
END$$

CREATE TRIGGER trg_procedure_room_overlap_bi
BEFORE INSERT ON procedure_event /* insert of an event */
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM procedure_event pe
        WHERE pe.place_id = NEW.place_id
          AND NEW.start_ts < pe.end_ts
          AND NEW.end_ts > pe.start_ts
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Two procedures cannot overlap in the same operating place.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM procedure_event pe
        WHERE pe.chief_surgeon_amka = NEW.chief_surgeon_amka
          AND NEW.start_ts < pe.end_ts
          AND NEW.end_ts > pe.start_ts
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The same chief surgeon cannot participate in overlapping procedures.';
    END IF;
END$$

CREATE TRIGGER trg_procedure_room_overlap_bu
BEFORE UPDATE ON procedure_event /* update of an event */
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM procedure_event pe
        WHERE pe.procedure_event_id != NEW.procedure_event_id  /* not equal */
          AND pe.place_id = NEW.place_id
          AND NEW.start_ts < pe.end_ts
          AND NEW.end_ts > pe.start_ts
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Two procedures cannot overlap in the same operating place.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM procedure_event pe
        WHERE pe.procedure_event_id != NEW.procedure_event_id /* not equal */
          AND pe.chief_surgeon_amka = NEW.chief_surgeon_amka
          AND NEW.start_ts < pe.end_ts
          AND NEW.end_ts > pe.start_ts
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The same chief surgeon cannot participate in overlapping procedures.';
    END IF;
END$$

CREATE TRIGGER trg_procedure_participant_overlap_bi
BEFORE INSERT ON procedure_participant
FOR EACH ROW
BEGIN
    DECLARE v_start DATETIME;
    DECLARE v_end DATETIME;

    SELECT start_ts, end_ts
      INTO v_start, v_end
      FROM procedure_event
     WHERE procedure_event_id = NEW.procedure_event_id;

    IF EXISTS (
        SELECT 1
        FROM procedure_participant pp
        JOIN procedure_event pe
          ON pe.procedure_event_id = pp.procedure_event_id
        WHERE pp.personnel_amka = NEW.personnel_amka 
          AND v_start < pe.end_ts
          AND v_end > pe.start_ts
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The same staff member cannot participate in overlapping procedures.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM procedure_event pe
        WHERE pe.chief_surgeon_amka = NEW.personnel_amka
          AND v_start < pe.end_ts
          AND v_end > pe.start_ts
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The same doctor cannot be chief surgeon in one procedure and participant in another at the same time.';
    END IF;
END$$

CREATE TRIGGER trg_procedure_place_type_bi
BEFORE INSERT ON procedure_event
FOR EACH ROW
BEGIN
    DECLARE v_required_place_type VARCHAR(30);
    DECLARE v_actual_place_type VARCHAR(30);

    SELECT required_place_type
      INTO v_required_place_type
      FROM procedure_catalog
     WHERE procedure_code = NEW.procedure_code;

    SELECT place_type
      INTO v_actual_place_type
      FROM operating_place
     WHERE place_id = NEW.place_id;

    IF v_required_place_type != v_actual_place_type THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Procedure event place type does not match the required place type of the procedure.';
    END IF;
END$$

CREATE TRIGGER trg_procedure_place_type_bu
BEFORE UPDATE ON procedure_event
FOR EACH ROW
BEGIN
    DECLARE v_required_place_type VARCHAR(30);
    DECLARE v_actual_place_type VARCHAR(30);

    SELECT required_place_type
      INTO v_required_place_type
      FROM procedure_catalog
     WHERE procedure_code = NEW.procedure_code;

    SELECT place_type
      INTO v_actual_place_type
      FROM operating_place
     WHERE place_id = NEW.place_id;

    IF v_required_place_type != v_actual_place_type THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Procedure event place type does not match the required place type of the procedure.';
    END IF;
END$$

CREATE TRIGGER trg_procedure_participant_not_chief_bi
BEFORE INSERT ON procedure_participant
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM procedure_event pe
        WHERE pe.procedure_event_id = NEW.procedure_event_id
          AND pe.chief_surgeon_amka = NEW.personnel_amka
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Chief surgeon must not be duplicated in procedure participants.';
    END IF;
END$$

CREATE TRIGGER trg_procedure_participant_not_admin_bi
BEFORE INSERT ON procedure_participant
FOR EACH ROW
BEGIN
    DECLARE v_type VARCHAR(20);
    SELECT personnel_type INTO v_type FROM personnel WHERE amka = NEW.personnel_amka;
    IF v_type = 'ADMIN' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Administrative staff cannot participate in procedures.';
    END IF;
END$$

CREATE TRIGGER trg_procedure_participant_not_admin_bu
BEFORE UPDATE ON procedure_participant
FOR EACH ROW
BEGIN
    DECLARE v_type VARCHAR(20);
    SELECT personnel_type INTO v_type FROM personnel WHERE amka = NEW.personnel_amka;
    IF v_type = 'ADMIN' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Administrative staff cannot participate in procedures.';
    END IF;
END$$

CREATE TRIGGER trg_shift_resident_supervisor_bi
BEFORE INSERT ON shift_assignment
FOR EACH ROW
BEGIN
    DECLARE supervisor_cnt INT DEFAULT 0;
    DECLARE doc_rank       VARCHAR(20);

    SELECT (
        SELECT d.doctor_rank
        FROM doctor d
        WHERE d.amka = NEW.personnel_amka
        LIMIT 1
    ) INTO doc_rank;

    IF doc_rank = 'RESIDENT' THEN
        SELECT COUNT(*) INTO supervisor_cnt
        FROM shift_assignment sa
        JOIN doctor d ON sa.personnel_amka = d.amka
        WHERE sa.shift_id = NEW.shift_id
            AND d.doctor_rank IN ('CONSULTANT_A', 'DIRECTOR'); 

        IF supervisor_cnt = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Resident doctor must have a supervisor';
        END IF;
        
    END IF;
END$$


CREATE TRIGGER trg_shift_resident_supervisor_bu
BEFORE UPDATE ON shift_assignment
FOR EACH ROW
BEGIN
    DECLARE supervisor_cnt INT DEFAULT 0;
    DECLARE doc_rank       VARCHAR(20);

    SELECT (
        SELECT d.doctor_rank
        FROM doctor d
        WHERE d.amka = NEW.personnel_amka
        LIMIT 1
    ) INTO doc_rank;

    IF doc_rank = 'RESIDENT' THEN
        SELECT COUNT(*) INTO supervisor_cnt
        FROM shift_assignment sa
        JOIN doctor d ON sa.personnel_amka = d.amka
        WHERE sa.shift_id = NEW.shift_id
            AND d.doctor_rank IN ('CONSULTANT_A', 'DIRECTOR'); 

        IF supervisor_cnt = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Resident doctor must have a supervisor';
        END IF;
        
    END IF;
END$$



CREATE TRIGGER trg_shift_monthly_limits_bi
BEFORE INSERT ON shift_assignment
FOR EACH ROW
BEGIN
    DECLARE shift_cnt      INT DEFAULT 0;
    DECLARE per_type       VARCHAR(20);
    DECLARE max_limit      INT;
    DECLARE v_shift_date   DATE;

    SELECT personnel_type INTO per_type
    FROM personnel
    WHERE amka = NEW.personnel_amka;

    SELECT shift_date INTO v_shift_date
    FROM department_shift
    WHERE shift_id = NEW.shift_id;

    SELECT COUNT(*) INTO shift_cnt
    FROM shift_assignment sa
    JOIN department_shift ds ON sa.shift_id = ds.shift_id
    WHERE sa.personnel_amka = NEW.personnel_amka
        AND MONTH(ds.shift_date) = MONTH(v_shift_date)
        AND YEAR(ds.shift_date) = YEAR(v_shift_date);

    IF per_type = 'DOCTOR' THEN 
        SET max_limit = 15;
    END IF;
    
    IF per_type = 'NURSE' THEN 
        SET max_limit = 20;
    END IF;

     IF per_type = 'ADMIN' THEN 
        SET max_limit = 25;
    END IF;

    IF shift_cnt >= max_limit THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Exceeding monthly shift limit.';
    END IF;

END$$  


CREATE TRIGGER trg_shift_monthly_limits_bu
BEFORE UPDATE ON shift_assignment
FOR EACH ROW
BEGIN
    DECLARE shift_cnt      INT DEFAULT 0;
    DECLARE per_type       VARCHAR(20);
    DECLARE max_limit      INT;
    DECLARE v_shift_date   DATE;

    SELECT personnel_type INTO per_type
    FROM personnel
    WHERE amka = NEW.personnel_amka;

    SELECT shift_date INTO v_shift_date
    FROM department_shift
    WHERE shift_id = NEW.shift_id;

    SELECT COUNT(*) INTO shift_cnt
    FROM shift_assignment sa
    JOIN department_shift ds ON sa.shift_id = ds.shift_id
    WHERE sa.personnel_amka = NEW.personnel_amka
        AND MONTH(ds.shift_date) = MONTH(v_shift_date)
        AND YEAR(ds.shift_date) = YEAR(v_shift_date)
        AND NOT (sa.shift_id = OLD.shift_id AND sa.personnel_amka = OLD.personnel_amka);

    IF per_type = 'DOCTOR' THEN 
        SET max_limit = 15;
    END IF;
    
    IF per_type = 'NURSE' THEN 
        SET max_limit = 20;
    END IF;

     IF per_type = 'ADMIN' THEN 
        SET max_limit = 25;
    END IF;

    IF shift_cnt >= max_limit THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Exceeding monthly shift limit.';
    END IF;

END$$  



CREATE TRIGGER trg_shift_rest_bi
BEFORE INSERT ON shift_assignment
FOR EACH ROW
BEGIN
    DECLARE new_date        DATE;
    DECLARE new_start       TIME;
    DECLARE new_start_dt    DATETIME;

    DECLARE old_date        DATE;
    DECLARE old_end         TIME;
    DECLARE old_type        VARCHAR(20);
    DECLARE prev_end_dt     DATETIME;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET old_date = NULL;

    /* Convert the new shift start to a full timestamp. */
    SELECT shift_date, start_time INTO new_date, new_start
    FROM department_shift
    WHERE shift_id = NEW.shift_id;

    SET new_start_dt = TIMESTAMP(new_date, new_start);

    /* Find the immediately previous shift for the same staff member. */
    SELECT ds.shift_date, ds.end_time, ds.shift_type 
    INTO old_date, old_end, old_type
    FROM shift_assignment sa
    JOIN department_shift ds ON sa.shift_id = ds.shift_id
    WHERE sa.personnel_amka = NEW.personnel_amka
      AND TIMESTAMP(ds.shift_date, ds.end_time) <= new_start_dt
    ORDER BY ds.shift_date DESC, ds.start_time DESC
    LIMIT 1;

    /* Compare rest time only when a previous shift exists. */
    IF old_date IS NOT NULL THEN
        
        SET prev_end_dt = TIMESTAMP(old_date, old_end);

        /* Night shifts end on the following calendar day. */
        IF old_type = 'NIGHT' THEN
            SET prev_end_dt = DATE_ADD(prev_end_dt, INTERVAL 1 DAY);
        END IF;

        /* Staff must rest at least eight hours between shifts. */
        IF TIMESTAMPDIFF(HOUR, prev_end_dt, new_start_dt) < 8 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rest must be at least 8 hours between shifts.';
        END IF;
        
    END IF;

END$$

CREATE TRIGGER trg_shift_rest_bu
BEFORE UPDATE ON shift_assignment
FOR EACH ROW
BEGIN
    DECLARE new_date        DATE;
    DECLARE new_start       TIME;
    DECLARE new_start_dt    DATETIME;

    DECLARE old_date        DATE;
    DECLARE old_end         TIME;
    DECLARE old_type        VARCHAR(20);
    DECLARE prev_end_dt     DATETIME;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET old_date = NULL;

    /* Convert the updated shift start to a full timestamp. */
    SELECT shift_date, start_time INTO new_date, new_start
    FROM department_shift
    WHERE shift_id = NEW.shift_id;

    SET new_start_dt = TIMESTAMP(new_date, new_start);

    /* Find the immediately previous shift for the same staff member. */
    SELECT ds.shift_date, ds.end_time, ds.shift_type 
    INTO old_date, old_end, old_type
    FROM shift_assignment sa
    JOIN department_shift ds ON sa.shift_id = ds.shift_id
    WHERE sa.personnel_amka = NEW.personnel_amka
      AND NOT (sa.shift_id = OLD.shift_id AND sa.personnel_amka = OLD.personnel_amka)
      AND TIMESTAMP(ds.shift_date, ds.end_time) <= new_start_dt
    ORDER BY ds.shift_date DESC, ds.start_time DESC
    LIMIT 1;

    /* Compare rest time only when a previous shift exists. */
    IF old_date IS NOT NULL THEN
        
        SET prev_end_dt = TIMESTAMP(old_date, old_end);

        /* Night shifts end on the following calendar day. */
        IF old_type = 'NIGHT' THEN
            SET prev_end_dt = DATE_ADD(prev_end_dt, INTERVAL 1 DAY);
        END IF;

        /* Staff must rest at least eight hours between shifts. */
        IF TIMESTAMPDIFF(HOUR, prev_end_dt, new_start_dt) < 8 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Rest must be at least 8 hours between shifts.';
        END IF;
        
    END IF;

END$$

CREATE TRIGGER trg_night_shifts_limit_bi
BEFORE INSERT ON shift_assignment
FOR EACH ROW
BEGIN
    DECLARE v_shift_type        VARCHAR(20);
    DECLARE night_shifts_cnt    INT DEFAULT 0;

    SELECT shift_type INTO v_shift_type
    FROM department_shift
    WHERE shift_id = NEW.shift_id;
    
    IF v_shift_type = 'NIGHT' THEN
        SELECT COUNT(*) INTO night_shifts_cnt
        FROM (
            SELECT ds.shift_type
            FROM shift_assignment sa
            JOIN department_shift ds ON ds.shift_id = sa.shift_id
            WHERE sa.personnel_amka = NEW.personnel_amka
                AND sa.shift_id != NEW.shift_id
            ORDER BY ds.shift_date DESC, ds.start_time DESC
            LIMIT 3)
        AS last_3_shifts
        WHERE shift_type = 'NIGHT';

        IF night_shifts_cnt >= 3 THEN 
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'There must not be more than 3 night shifts in a row.';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_night_shifts_limit_bu
BEFORE UPDATE ON shift_assignment
FOR EACH ROW
BEGIN
    DECLARE v_shift_type        VARCHAR(20);
    DECLARE night_shifts_cnt    INT DEFAULT 0;

    SELECT shift_type INTO v_shift_type
    FROM department_shift
    WHERE shift_id = NEW.shift_id;
    
    IF v_shift_type = 'NIGHT' THEN
        SELECT COUNT(*) INTO night_shifts_cnt
        FROM (
            SELECT ds.shift_type
            FROM shift_assignment sa
            JOIN department_shift ds ON ds.shift_id = sa.shift_id
            WHERE sa.personnel_amka = NEW.personnel_amka
                AND NOT (sa.shift_id = OLD.shift_id AND sa.personnel_amka = OLD.personnel_amka)
            ORDER BY ds.shift_date DESC, ds.start_time DESC
            LIMIT 3)
        AS last_3_shifts
        WHERE shift_type = 'NIGHT';

        IF night_shifts_cnt >= 3 THEN 
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'There must not be more than 3 night shifts in a row.';
        END IF;
    END IF;
END$$

CREATE TRIGGER trg_extra_hospitalization_cost_bi
BEFORE INSERT ON hospitalization
FOR EACH ROW
BEGIN
    DECLARE v_basic_cost            NUMERIC(12,2);
    DECLARE v_mean_duration_days    INT;
    DECLARE total_days              INT;
    DECLARE v_extra_daily_cost      NUMERIC(12,2);


    SELECT basic_cost, mean_duration_days, extra_daily_cost INTO v_basic_cost, v_mean_duration_days, v_extra_daily_cost
    FROM ken
    WHERE ken_code = NEW.ken_code;

    IF NEW.discharge_ts IS NULL THEN
        SET NEW.total_cost = v_basic_cost;
    ELSE
        SET total_days = GREATEST(1, CEIL(TIMESTAMPDIFF(HOUR, NEW.admission_ts, NEW.discharge_ts) / 24));

        IF total_days <= v_mean_duration_days THEN
            SET NEW.total_cost = v_basic_cost;
        END IF;

        IF total_days > v_mean_duration_days THEN
            SET NEW.total_cost = v_basic_cost + (total_days - v_mean_duration_days) * v_extra_daily_cost;
        END IF;
    END IF;

END$$

CREATE TRIGGER trg_extra_hospitalization_cost_bu
BEFORE UPDATE ON hospitalization
FOR EACH ROW
BEGIN
    DECLARE v_basic_cost            NUMERIC(12,2);
    DECLARE v_mean_duration_days    INT;
    DECLARE total_days              INT;
    DECLARE v_extra_daily_cost      NUMERIC(12,2);


    SELECT basic_cost, mean_duration_days, extra_daily_cost INTO v_basic_cost, v_mean_duration_days, v_extra_daily_cost
    FROM ken
    WHERE ken_code = NEW.ken_code;

    IF NEW.discharge_ts IS NULL THEN
        SET NEW.total_cost = v_basic_cost;
    ELSE
        SET total_days = GREATEST(1, CEIL(TIMESTAMPDIFF(HOUR, NEW.admission_ts, NEW.discharge_ts) / 24));

        IF total_days <= v_mean_duration_days THEN
            SET NEW.total_cost = v_basic_cost;
        END IF;

        IF total_days > v_mean_duration_days THEN
            SET NEW.total_cost = v_basic_cost + (total_days - v_mean_duration_days) * v_extra_daily_cost;
        END IF;
    END IF;

END$$

/* ---------------------------------------------------------------------------
   Workflow stored procedures.
   Procedures centralize common application actions. The existing constraints
   and triggers still perform the final safety checks.
--------------------------------------------------------------------------- */

CREATE PROCEDURE sp_next_emergency_visit(IN p_department_id INT)
BEGIN
    SELECT *
    FROM v_emergency_fifo_queue
    WHERE p_department_id IS NULL
       OR referred_department_id = p_department_id
    ORDER BY emergency_level, arrival_ts, visit_id
    LIMIT 1;
END$$

CREATE PROCEDURE sp_start_emergency_service(IN p_visit_id BIGINT)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    DECLARE v_arrival DATETIME;
    DECLARE v_service_start DATETIME;
    DECLARE v_service_end DATETIME;

    SELECT COUNT(*)
      INTO v_exists
      FROM emergency_visit
     WHERE visit_id = p_visit_id;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Emergency visit does not exist.';
    END IF;

    SELECT arrival_ts, service_start_ts, service_end_ts
      INTO v_arrival, v_service_start, v_service_end
      FROM emergency_visit
     WHERE visit_id = p_visit_id;

    IF v_service_end IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Emergency visit is already finished.';
    END IF;

    IF v_service_start IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Emergency service has already started.';
    END IF;

    UPDATE emergency_visit
       SET service_start_ts = CASE
             WHEN NOW() < v_arrival THEN v_arrival
             ELSE NOW()
           END
     WHERE visit_id = p_visit_id;

    SELECT *
    FROM emergency_visit
    WHERE visit_id = p_visit_id;
END$$

CREATE PROCEDURE sp_finish_emergency_service(
    IN p_visit_id BIGINT,
    IN p_disposition VARCHAR(20),
    IN p_referred_department_id INT
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    DECLARE v_arrival DATETIME;
    DECLARE v_service_start DATETIME;
    DECLARE v_service_end DATETIME;
    DECLARE v_final_start DATETIME;
    DECLARE v_final_end DATETIME;

    SELECT COUNT(*)
      INTO v_exists
      FROM emergency_visit
     WHERE visit_id = p_visit_id;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Emergency visit does not exist.';
    END IF;

    IF p_disposition IS NULL OR p_disposition NOT IN ('DISCHARGED', 'HOSPITALIZED') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid emergency disposition.';
    END IF;

    IF p_disposition = 'HOSPITALIZED' AND p_referred_department_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Hospitalized emergency visits require a referred department.';
    END IF;

    SELECT arrival_ts, service_start_ts, service_end_ts
      INTO v_arrival, v_service_start, v_service_end
      FROM emergency_visit
     WHERE visit_id = p_visit_id;

    IF v_service_end IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Emergency visit is already finished.';
    END IF;

    SET v_final_start = COALESCE(v_service_start, CASE WHEN NOW() < v_arrival THEN v_arrival ELSE NOW() END);
    SET v_final_end = CASE WHEN NOW() < v_final_start THEN v_final_start ELSE NOW() END;

    UPDATE emergency_visit
       SET service_start_ts = v_final_start,
           service_end_ts = v_final_end,
           disposition = p_disposition,
           referred_department_id = CASE
             WHEN p_disposition = 'HOSPITALIZED' THEN p_referred_department_id
             ELSE NULL
           END
     WHERE visit_id = p_visit_id;

    SELECT *
    FROM emergency_visit
    WHERE visit_id = p_visit_id;
END$$

CREATE PROCEDURE sp_admit_patient(
    IN p_patient_amka CHAR(11),
    IN p_department_id INT,
    IN p_emergency_visit_id BIGINT,
    IN p_ken_code VARCHAR(20),
    IN p_admission_icd10_code VARCHAR(20),
    IN p_primary_doctor_amka CHAR(11),
    IN p_admission_ts DATETIME
)
BEGIN
    DECLARE v_bed_id INT DEFAULT NULL;
    DECLARE v_hosp_id BIGINT;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_bed_id = NULL;

    IF NOT EXISTS (
        SELECT 1
        FROM doctor_department
        WHERE doctor_amka = p_primary_doctor_amka
          AND department_id = p_department_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Primary doctor is not assigned to the admission department.';
    END IF;

    SELECT b.bed_id
      INTO v_bed_id
      FROM bed b
     WHERE b.department_id = p_department_id
       AND b.bed_status = 'AVAILABLE'
       AND NOT EXISTS (
           SELECT 1
           FROM hospitalization h
           WHERE h.bed_id = b.bed_id
             AND h.admission_ts <= p_admission_ts
             AND (h.discharge_ts IS NULL OR h.discharge_ts > p_admission_ts)
       )
     ORDER BY FIELD(b.bed_type, 'MULTI_BED', 'SINGLE', 'ICU'), b.bed_number
     LIMIT 1;

    IF v_bed_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No available bed found for this department.';
    END IF;

    INSERT INTO hospitalization (
        patient_amka,
        department_id,
        bed_id,
        emergency_visit_id,
        ken_code,
        admission_ts,
        admission_icd10_code
    ) VALUES (
        p_patient_amka,
        p_department_id,
        v_bed_id,
        p_emergency_visit_id,
        p_ken_code,
        p_admission_ts,
        p_admission_icd10_code
    );

    SET v_hosp_id = LAST_INSERT_ID();

    INSERT INTO hospitalization_doctor (hosp_id, doctor_amka, doctor_role, is_primary)
    VALUES (v_hosp_id, p_primary_doctor_amka, 'PRIMARY', TRUE);

    UPDATE bed
       SET bed_status = 'OCCUPIED'
     WHERE bed_id = v_bed_id;

    SELECT *
    FROM hospitalization
    WHERE hosp_id = v_hosp_id;
END$$

CREATE PROCEDURE sp_discharge_patient(
    IN p_hosp_id BIGINT,
    IN p_discharge_ts DATETIME,
    IN p_discharge_icd10_code VARCHAR(20)
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    DECLARE v_bed_id INT;
    DECLARE v_admission_ts DATETIME;
    DECLARE v_discharge_ts DATETIME;

    SELECT COUNT(*)
      INTO v_exists
      FROM hospitalization
     WHERE hosp_id = p_hosp_id;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Hospitalization does not exist.';
    END IF;

    SELECT bed_id, admission_ts
      INTO v_bed_id, v_admission_ts
      FROM hospitalization
     WHERE hosp_id = p_hosp_id;

    SET v_discharge_ts = COALESCE(p_discharge_ts, NOW());

    IF v_discharge_ts < v_admission_ts THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Discharge timestamp cannot be before admission timestamp.';
    END IF;

    UPDATE hospitalization
       SET discharge_ts = v_discharge_ts,
           discharge_icd10_code = p_discharge_icd10_code
     WHERE hosp_id = p_hosp_id;

    UPDATE bed
       SET bed_status = 'AVAILABLE'
     WHERE bed_id = v_bed_id
       AND NOT EXISTS (
           SELECT 1
           FROM hospitalization h
           WHERE h.bed_id = v_bed_id
             AND h.hosp_id <> p_hosp_id
             AND h.admission_ts <= v_discharge_ts
             AND (h.discharge_ts IS NULL OR h.discharge_ts > v_discharge_ts)
       );

    SELECT *
    FROM hospitalization
    WHERE hosp_id = p_hosp_id;
END$$

CREATE PROCEDURE sp_prescribe_drug_safely(
    IN p_hosp_id BIGINT,
    IN p_patient_amka CHAR(11),
    IN p_doctor_amka CHAR(11),
    IN p_drug_id VARCHAR(80),
    IN p_dosage VARCHAR(120),
    IN p_frequency VARCHAR(120),
    IN p_start_datetime DATETIME,
    IN p_end_datetime DATETIME
)
BEGIN
    DECLARE v_prescription_id BIGINT;

    IF EXISTS (
        SELECT 1
        FROM patient_allergy pa
        JOIN drug_active_substance das ON das.substance_id = pa.substance_id
        WHERE pa.patient_amka = p_patient_amka
          AND das.drug_id = p_drug_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Prescription forbidden: patient is allergic to an active substance of this drug.';
    END IF;

    INSERT INTO prescription (
        hosp_id,
        patient_amka,
        doctor_amka,
        drug_id,
        dosage,
        frequency,
        start_datetime,
        end_datetime
    ) VALUES (
        p_hosp_id,
        p_patient_amka,
        p_doctor_amka,
        p_drug_id,
        p_dosage,
        p_frequency,
        p_start_datetime,
        p_end_datetime
    );

    SET v_prescription_id = LAST_INSERT_ID();

    SELECT *
    FROM prescription
    WHERE prescription_id = v_prescription_id;
END$$

CREATE PROCEDURE sp_schedule_procedure(
    IN p_hosp_id BIGINT,
    IN p_procedure_code VARCHAR(30),
    IN p_place_id INT,
    IN p_chief_surgeon_amka CHAR(11),
    IN p_start_ts DATETIME,
    IN p_end_ts DATETIME
)
BEGIN
    DECLARE v_procedure_event_id BIGINT;

    INSERT INTO procedure_event (
        hosp_id,
        procedure_code,
        place_id,
        chief_surgeon_amka,
        start_ts,
        end_ts,
        actual_duration_min
    ) VALUES (
        p_hosp_id,
        p_procedure_code,
        p_place_id,
        p_chief_surgeon_amka,
        p_start_ts,
        p_end_ts,
        TIMESTAMPDIFF(MINUTE, p_start_ts, p_end_ts)
    );

    SET v_procedure_event_id = LAST_INSERT_ID();

    SELECT *
    FROM procedure_event
    WHERE procedure_event_id = v_procedure_event_id;
END$$

CREATE PROCEDURE sp_add_procedure_participant(
    IN p_procedure_event_id BIGINT,
    IN p_personnel_amka CHAR(11),
    IN p_participant_role VARCHAR(40)
)
BEGIN
    INSERT INTO procedure_participant (procedure_event_id, personnel_amka, participant_role)
    VALUES (p_procedure_event_id, p_personnel_amka, p_participant_role);

    SELECT *
    FROM procedure_participant
    WHERE procedure_event_id = p_procedure_event_id
      AND personnel_amka = p_personnel_amka;
END$$

CREATE PROCEDURE sp_assign_staff_to_shift(
    IN p_shift_id BIGINT,
    IN p_personnel_amka CHAR(11),
    IN p_assigned_role VARCHAR(40)
)
BEGIN
    INSERT INTO shift_assignment (shift_id, personnel_amka, assigned_role)
    VALUES (p_shift_id, p_personnel_amka, p_assigned_role);

    SELECT *
    FROM shift_assignment
    WHERE shift_id = p_shift_id
      AND personnel_amka = p_personnel_amka;
END$$

CREATE PROCEDURE sp_record_evaluation(
    IN p_hosp_id BIGINT,
    IN p_evaluation_date DATE,
    IN p_medical_care_score INT,
    IN p_nursing_care_score INT,
    IN p_cleanliness_score INT,
    IN p_food_score INT,
    IN p_overall_experience_score INT,
    IN p_comments TEXT
)
BEGIN
    DECLARE v_discharge_ts DATETIME;
    DECLARE v_exists INT DEFAULT 0;

    SELECT COUNT(*)
      INTO v_exists
      FROM hospitalization
     WHERE hosp_id = p_hosp_id;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Hospitalization does not exist.';
    END IF;

    SELECT discharge_ts
      INTO v_discharge_ts
      FROM hospitalization
     WHERE hosp_id = p_hosp_id;

    IF v_discharge_ts IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Evaluation can be recorded only after discharge.';
    END IF;

    IF p_evaluation_date < DATE(v_discharge_ts) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Evaluation date cannot be before discharge date.';
    END IF;

    INSERT INTO hospitalization_evaluation (
        hosp_id,
        evaluation_date,
        medical_care_score,
        nursing_care_score,
        cleanliness_score,
        food_score,
        overall_experience_score,
        comments
    ) VALUES (
        p_hosp_id,
        p_evaluation_date,
        p_medical_care_score,
        p_nursing_care_score,
        p_cleanliness_score,
        p_food_score,
        p_overall_experience_score,
        p_comments
    )
    ON DUPLICATE KEY UPDATE
        evaluation_date = VALUES(evaluation_date),
        medical_care_score = VALUES(medical_care_score),
        nursing_care_score = VALUES(nursing_care_score),
        cleanliness_score = VALUES(cleanliness_score),
        food_score = VALUES(food_score),
        overall_experience_score = VALUES(overall_experience_score),
        comments = VALUES(comments);

    SELECT *
    FROM hospitalization_evaluation
    WHERE hosp_id = p_hosp_id;
END$$

DELIMITER ;
