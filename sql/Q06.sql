USE yg_eupolis_hospital;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Q06: Hospitalization history for one patient with diagnoses, KEN cost,
-- and evaluation average. The patient is selected from the loaded data
-- by highest hospitalization count so the output is non-empty.
SET @target_patient_amka = (
    SELECT h.patient_amka
    FROM hospitalization h
    JOIN hospitalization_evaluation he ON he.hosp_id = h.hosp_id
    GROUP BY h.patient_amka
    ORDER BY COUNT(*) DESC, h.patient_amka
    LIMIT 1
);

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
    GROUP BY h.patient_amka
)
SELECT
    ph.patient_amka,
    ph.first_name,
    ph.last_name,
    ph.hosp_id,
    ph.department_name,
    ph.admission_ts,
    ph.discharge_ts,
    ph.icd10_code AS admission_icd10_code,
    ph.icd10_description AS admission_diagnosis,
    h.discharge_icd10_code,
    disc.icd10_description AS discharge_diagnosis,
    ph.ken_code,
    ph.ken_description,
    ROUND(ph.total_cost, 2) AS total_cost,
    pe.patient_overall_evaluation_average,
    ROUND((
        he.medical_care_score
        + he.nursing_care_score
        + he.cleanliness_score
        + he.food_score
        + he.overall_experience_score
    ) / 5, 2) AS hospitalization_evaluation_average
FROM patient_history ph
JOIN hospitalization h ON h.hosp_id = ph.hosp_id
LEFT JOIN icd10_diagnosis disc ON disc.icd10_code = h.discharge_icd10_code
LEFT JOIN hospitalization_evaluation he ON he.hosp_id = ph.hosp_id
LEFT JOIN patient_eval pe ON pe.patient_amka = ph.patient_amka
WHERE ph.patient_amka = @target_patient_amka
ORDER BY ph.admission_ts;
