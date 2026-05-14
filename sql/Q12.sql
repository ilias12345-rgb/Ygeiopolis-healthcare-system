SELECT department_name, shift_type, shift_date, COUNT(*) AS required_personnel,
    CASE
        WHEN s.personnel_type = 'DOCTOR' THEN d.specialization
        WHEN s.personnel_type = 'NURSE'  THEN n.nurse_rank
        WHEN s.personnel_type = 'ADMIN'  THEN ad.admin_role
    END AS personnel_subclass
FROM shift_staff s
LEFT JOIN doctor d ON s.personnel_amka = d.amka
LEFT JOIN nurse n ON s.personnel_amka = n.amka
LEFT JOIN administrative_staff ad ON s.personnel_amka = ad.amka
WHERE WEEK(s.shift_date) = WEEK('2026-03-10')
GROUP BY s.department_name, s.shift_date, s.shift_type, personnel_subclass
ORDER BY s.shift_date, s.department_name, s.shift_type;
