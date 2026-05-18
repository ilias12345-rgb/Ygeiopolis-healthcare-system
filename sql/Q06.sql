USE yg_eupolis_hospital;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Q06: Hospitalization history for one patient with diagnoses, KEN cost,
-- and evaluation averages.

-- Pick one patient that has hospitalization evaluations.
-- The chosen patient is deterministic: the one with the most evaluated
-- hospitalizations, and the smallest AMKA in case of a tie.
SET @target_patient_amka = (
    SELECT h.patient_amka
    FROM hospitalization h
    JOIN hospitalization_evaluation he ON he.hosp_id = h.hosp_id -- keep only evaluated hospitalizations
    GROUP BY h.patient_amka
    ORDER BY COUNT(*) DESC, h.patient_amka
    LIMIT 1
);

-- Compute the selected patient's average evaluation once, then reuse it
-- for every hospitalization row in the final result.
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
    JOIN hospitalization_evaluation he ON he.hosp_id = h.hosp_id -- scores belong to each hospitalization
    WHERE h.patient_amka = @target_patient_amka -- restrict the average to the selected patient
    GROUP BY h.patient_amka
)
SELECT
    -- Patient identity.
    p.patient_amka,
    p.first_name,
    p.last_name,

    -- Hospitalization facts.
    h.hosp_id,
    d.department_name,
    h.admission_ts,
    h.discharge_ts,

    -- Admission and discharge diagnoses.
    h.admission_icd10_code,
    adm.icd10_description AS admission_diagnosis,
    h.discharge_icd10_code,
    disc.icd10_description AS discharge_diagnosis,

    -- KEN billing information.
    h.ken_code,
    k.ken_description,
    ROUND(h.total_cost, 2) AS total_cost,

    -- Patient-level average evaluation across all evaluated hospitalizations.
    pe.patient_overall_evaluation_average,

    -- Evaluation average for this specific hospitalization.
    ROUND((
        he.medical_care_score
        + he.nursing_care_score
        + he.cleanliness_score
        + he.food_score
        + he.overall_experience_score
    ) / 5, 2) AS hospitalization_evaluation_average
FROM patient p
JOIN hospitalization h
    -- idx_hosp_patient_admission_q6 supports patient filtering and admission-date ordering.
    ON h.patient_amka = p.patient_amka
JOIN department d ON d.department_id = h.department_id -- department where the patient was hospitalized
JOIN ken k ON k.ken_code = h.ken_code -- KEN description and cost category
JOIN icd10_diagnosis adm ON adm.icd10_code = h.admission_icd10_code -- admission diagnosis is mandatory
LEFT JOIN icd10_diagnosis disc ON disc.icd10_code = h.discharge_icd10_code -- discharge diagnosis may be missing
LEFT JOIN hospitalization_evaluation he ON he.hosp_id = h.hosp_id -- keep hospitalizations even if no evaluation exists
LEFT JOIN patient_eval pe ON pe.patient_amka = p.patient_amka -- attach the patient-level average
WHERE p.patient_amka = @target_patient_amka -- show history only for the selected patient
ORDER BY h.admission_ts DESC; -- newest hospitalizations first
