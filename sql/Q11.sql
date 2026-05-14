SELECT p.first_name, p.last_name, d.amka, COUNT(*) AS total_procedures
FROM doctor d
JOIN personnel p ON p.amka = d.amka
JOIN procedure_event pe ON d.amka = pe.chief_surgeon_amka
WHERE YEAR(pe.start_ts) = YEAR(CURDATE())
GROUP BY d.amka, p.first_name, p.last_name
HAVING total_procedures + 5 <= (
    SELECT COUNT(*)
    FROM procedure_event
    WHERE YEAR(start_ts) = YEAR(CURDATE())
    GROUP BY chief_surgeon_amka
    ORDER BY COUNT(*) DESC
    LIMIT 1
);
