USE yg_eupolis_hospital;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Q06: Hospitalization history for one patient with diagnoses, KEN cost,
-- and evaluation average. The FORCE INDEX version is useful for the Q06
-- EXPLAIN ANALYZE comparison required by the assignment.
SET @target_patient_amka = (
    SELECT h.patient_amka
    FROM hospitalization h
    JOIN hospitalization_evaluation he ON he.hosp_id = h.hosp_id
    GROUP BY h.patient_amka
    ORDER BY COUNT(*) DESC, h.patient_amka
    LIMIT 1
);

EXPLAIN ANALYZE
WITH patient_eval AS (
    SELECT
        h.patient_amka,
        ROUND(AVG((
            he.medical_care_score
            + he.nursing_care_score
            + he.cleanliness_score
            + he.food_score
            + he.overall_experience_score
    ) / 5), 2) AS patient_overall_evaluation_average
    FROM hospitalization h
    JOIN hospitalization_evaluation he ON he.hosp_id = h.hosp_id
    WHERE h.patient_amka = @target_patient_amka
    GROUP BY h.patient_amka
)
SELECT
    p.patient_amka,
    p.first_name,
    p.last_name,
    h.hosp_id,
    d.department_name,
    h.admission_ts,
    h.discharge_ts,
    h.admission_icd10_code,
    adm.icd10_description AS admission_diagnosis,
    h.discharge_icd10_code,
    disc.icd10_description AS discharge_diagnosis,
    h.ken_code,
    k.ken_description,
    ROUND(h.total_cost, 2) AS total_cost,
    pe.patient_overall_evaluation_average,
    ROUND((
        he.medical_care_score
        + he.nursing_care_score
        + he.cleanliness_score
        + he.food_score
        + he.overall_experience_score
    ) / 5, 2) AS hospitalization_evaluation_average
FROM patient p
JOIN hospitalization h FORCE INDEX (idx_hosp_patient_dept_dates)
    ON h.patient_amka = p.patient_amka
JOIN department d ON d.department_id = h.department_id
JOIN ken k ON k.ken_code = h.ken_code
JOIN icd10_diagnosis adm ON adm.icd10_code = h.admission_icd10_code
LEFT JOIN icd10_diagnosis disc ON disc.icd10_code = h.discharge_icd10_code
LEFT JOIN hospitalization_evaluation he ON he.hosp_id = h.hosp_id
LEFT JOIN patient_eval pe ON pe.patient_amka = p.patient_amka
WHERE p.patient_amka = @target_patient_amka
ORDER BY h.admission_ts DESC;
