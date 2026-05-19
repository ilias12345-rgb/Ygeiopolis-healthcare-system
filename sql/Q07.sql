USE ygeiopolis;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

/* Q07: For every active substance, count allergy declarations and the
 number of official EMA drugs that contain it.*/
SELECT
    a.substance_id,
    a.substance_name,
    COUNT(DISTINCT pa.patient_amka) AS allergic_patient_count,
    COUNT(DISTINCT das.drug_id) AS containing_drug_count
FROM active_substance a
LEFT JOIN patient_allergy pa
    ON pa.substance_id = a.substance_id
LEFT JOIN drug_active_substance das
    ON das.substance_id = a.substance_id
GROUP BY
    a.substance_id,
    a.substance_name
ORDER BY
    allergic_patient_count DESC,
    containing_drug_count DESC,
    a.substance_name;
