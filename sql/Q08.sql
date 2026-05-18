USE yg_eupolis_hospital;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Q08: Personnel not assigned to a specific department shift date.
SELECT first_name, last_name, amka, personnel_type
FROM personnel
WHERE amka NOT IN (
    SELECT personnel_amka
    FROM shift_assignment sa
    JOIN department_shift ds ON ds.shift_id = sa.shift_id
    WHERE ds.shift_date = '2026-03-03'
        AND ds.department_id = 5
    );
