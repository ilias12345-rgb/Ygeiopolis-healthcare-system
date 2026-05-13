USE yg_eupolis_hospital;

WITH young_surgeon_counts AS (
    SELECT
        doctor_amka,
        doctor_name,
        doctor_age,
        specialization,
        doctor_rank,
        department_names,
        COUNT(DISTINCT procedure_event_id) AS surgical_procedures_as_chief
    FROM v_doctor_procedure_event
    WHERE doctor_age < 35
      AND procedure_category = 'SURGICAL'
    GROUP BY
        doctor_amka,
        doctor_name,
        doctor_age,
        specialization,
        doctor_rank,
        department_names
    HAVING COUNT(DISTINCT procedure_event_id) > 0
),
max_count AS (
    SELECT MAX(surgical_procedures_as_chief) AS max_surgical_procedures
    FROM young_surgeon_counts
)
SELECT
    ysc.doctor_amka,
    ysc.doctor_name,
    ysc.doctor_age,
    ysc.specialization,
    ysc.doctor_rank,
    ysc.department_names,
    ysc.surgical_procedures_as_chief
FROM young_surgeon_counts ysc
CROSS JOIN max_count mc
WHERE ysc.surgical_procedures_as_chief = mc.max_surgical_procedures
ORDER BY ysc.doctor_name;