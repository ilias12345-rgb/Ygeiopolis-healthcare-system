USE yg_eupolis_hospital;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

SET @target_doctor_amka = (
    SELECT hd.doctor_amka
    FROM hospitalization_doctor hd FORCE INDEX (PRIMARY)
    JOIN hospitalization_evaluation he FORCE INDEX (PRIMARY) ON he.hosp_id = hd.hosp_id
    GROUP BY hd.doctor_amka
    ORDER BY COUNT(*) DESC, hd.doctor_amka
    LIMIT 1
);

EXPLAIN ANALYZE
SELECT
    d.amka AS doctor_amka,
    CONCAT(p.first_name, ' ', p.last_name) AS doctor_name,
    d.specialization,
    d.doctor_rank,
    COUNT(DISTINCT he.hosp_id) AS evaluated_hospitalizations,
    ROUND(AVG(he.medical_care_score), 2) AS avg_medical_care_score,
    ROUND(AVG(he.overall_experience_score), 2) AS avg_overall_experience_score
FROM doctor d
JOIN personnel p ON p.amka = d.amka
JOIN hospitalization_doctor hd FORCE INDEX (PRIMARY)
    ON hd.doctor_amka = d.amka
JOIN hospitalization_evaluation he FORCE INDEX (PRIMARY)
    ON he.hosp_id = hd.hosp_id
WHERE d.amka = @target_doctor_amka
GROUP BY
    d.amka,
    p.first_name,
    p.last_name,
    d.specialization,
    d.doctor_rank;
