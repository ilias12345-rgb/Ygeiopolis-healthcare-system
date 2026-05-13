SELECT d.first_name, d.last_name, d.amka, COUNT(*) AS total_procedures
FROM doctor d
JOIN procedure_event pe ON d.amka = pe.chief_surgeon_amka
WHERE YEAR(pe.start_ts) = 2025
GROUP BY d.amka, d.first_name, d.last_name
HAVING total_procedures + 5 <= (
    SELECT COUNT(*)
    FROM procedure_event
    WHERE YEAR(start_ts) = YEAR(CURDATE())
    GROUP BY chief_surgeon_amka
    ORDER BY COUNT(*) DESC
    LIMIT 1
);
