WITH patient_totals AS (
    SELECT patient_amka, first_name, last_name, SUM(DATEDIFF(discharge_ts, admission_ts)) AS total_days
    FROM patient_history
    GROUP BY patient_amka, first_name, last_name
)
SELECT *
FROM patient_totals
WHERE total_days > 15
AND total_days IN (
    SELECT total_days
    FROM patient_totals
    GROUP BY total_days
    HAVING COUNT(*) > 1
)
ORDER BY total_days;
