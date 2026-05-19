USE ygeiopolis;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

/*Q13: Recursive doctor-supervisor hierarchy.*/
WITH RECURSIVE sup_hierarchy AS (
    /*Start from every doctor that has a supervisor.*/
    SELECT amka AS doctor_amka, amka AS current_doctor_amka, supervisor_amka AS current_sup_amka, 1 AS lvl
    FROM doctor
    WHERE supervisor_amka IS NOT NULL

    UNION ALL

    /* Walk upward one supervisor at a time until the top of the hierarchy.*/
    SELECT sh.doctor_amka, d.amka, d.supervisor_amka, sh.lvl + 1
    FROM sup_hierarchy sh
    JOIN doctor d ON sh.current_sup_amka = d.amka
    WHERE d.supervisor_amka IS NOT NULL
)
SELECT
    s.doctor_amka AS initial_doctor_amka,
    p_curr.first_name AS first_name,
    p_curr.last_name AS last_name,
    d_curr.doctor_rank AS doctor_rank,
    s.current_sup_amka AS supervisor_amka,
    p_sup.first_name AS supervisor_first_name,
    p_sup.last_name AS supervisor_last_name,
    d_sup.doctor_rank AS supervisor_rank,
    s.lvl AS level
FROM sup_hierarchy s
JOIN personnel p_curr ON s.current_doctor_amka = p_curr.amka
JOIN doctor d_curr ON s.current_doctor_amka = d_curr.amka
JOIN personnel p_sup ON s.current_sup_amka = p_sup.amka
JOIN doctor d_sup ON s.current_sup_amka = d_sup.amka
ORDER BY initial_doctor_amka, level;
