USE yg_eupolis_hospital;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

SET @target_specialization = 'CARDIOLOGY';
SET @target_year = YEAR(CURDATE());

WITH shiftcnt AS (
    SELECT
        personnel_amka AS doctor_amka,
        COUNT(DISTINCT shift_id) AS shift_total
    FROM v_shift_staff
    WHERE personnel_type = 'DOCTOR'
      AND shift_year = @target_year
    GROUP BY personnel_amka
),

surgcnt AS (
    SELECT
        doctor_amka,
        COUNT(DISTINCT procedure_event_id) AS procedure_total
    FROM v_doctor_procedure_event
    WHERE procedure_category = 'SURGICAL'
      AND procedure_year = @target_year
    GROUP BY doctor_amka
),

target_doctors AS (
    SELECT DISTINCT
        doctor_amka,
        doctor_name,
        specialization,
        doctor_rank,
        department_names
    FROM v_doctor_procedure_event
    WHERE specialization = @target_specialization
)

SELECT
    td.doctor_amka,
    td.doctor_name,
    td.specialization,
    td.doctor_rank,
    td.department_names,

    CASE
        WHEN COALESCE(sc.shift_total, 0) > 0 THEN 'YES'
        ELSE 'NO'
    END AS had_shift_this_year,

    COALESCE(sc.shift_total, 0) AS shifts_this_year,
    COALESCE(sg.procedure_total, 0) AS surgical_procedures_as_chief

FROM target_doctors td
LEFT JOIN shiftcnt sc
    ON sc.doctor_amka = td.doctor_amka
LEFT JOIN surgcnt sg
    ON sg.doctor_amka = td.doctor_amka

ORDER BY
    surgical_procedures_as_chief DESC,
    shifts_this_year DESC,
    td.doctor_name;
