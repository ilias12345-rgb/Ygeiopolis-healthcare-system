USE ygeiopolis;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

SET @target_specialization = 'CARDIOLOGY';
SET @target_year = 2026;

/*Q02: Doctors of one specialization, with yearly shifts and surgical work.*/
SELECT
    d.amka AS doctor_amka,
    CONCAT(p.first_name, ' ', p.last_name) AS doctor_name,
    d.specialization,
    d.doctor_rank,
    GROUP_CONCAT(DISTINCT dep.department_name ORDER BY dep.department_name SEPARATOR ', ') AS department_names,

    CASE
        WHEN COALESCE(sc.shift_total, 0) > 0 THEN 'YES'
        ELSE 'NO'
    END AS had_shift_this_year,

    COALESCE(sc.shift_total, 0) AS shifts_this_year,
    COALESCE(sg.procedure_total, 0) AS surgical_procedures_as_chief

FROM doctor d
JOIN personnel p ON p.amka = d.amka
LEFT JOIN doctor_department dd ON dd.doctor_amka = d.amka
LEFT JOIN department dep ON dep.department_id = dd.department_id
LEFT JOIN (
    SELECT
        personnel_amka AS doctor_amka,
        COUNT(DISTINCT shift_id) AS shift_total
    FROM shift_staff
    WHERE personnel_type = 'DOCTOR'
      AND shift_year = @target_year
    GROUP BY personnel_amka
) sc ON sc.doctor_amka = d.amka
LEFT JOIN (
    SELECT
        doctor_amka,
        COUNT(DISTINCT procedure_event_id) AS procedure_total
    FROM v_doctor_procedure_event
    WHERE procedure_category = 'SURGICAL'
      AND procedure_year = @target_year
    GROUP BY doctor_amka
) sg ON sg.doctor_amka = d.amka
WHERE d.specialization = @target_specialization
GROUP BY
    d.amka,
    p.first_name,
    p.last_name,
    d.specialization,
    d.doctor_rank,
    sc.shift_total,
    sg.procedure_total

ORDER BY
    surgical_procedures_as_chief DESC,
    shifts_this_year DESC,
    doctor_name;
