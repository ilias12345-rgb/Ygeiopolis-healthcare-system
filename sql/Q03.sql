USE yg_eupolis_hospital;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Q03: Patients hospitalized more than three times in the same department.
SELECT
    patient_amka,
    patient_name,
    department_name,
    COUNT(hosp_id) AS hospitalization_count,
    ROUND(SUM(total_cost), 2) AS total_hospitalization_cost

FROM v_patient_hospitalization

GROUP BY
    patient_amka,
    patient_name,
    department_id,
    department_name

HAVING COUNT(hosp_id) > 3

ORDER BY
    hospitalization_count DESC,
    total_hospitalization_cost DESC;
