WITH patient_totals AS (
    SELECT 
        patient_amka, 
        first_name, 
        last_name, 
        YEAR(admission_ts) AS hosp_year, /*Εξαγωγή του έτους*/
        SUM(DATEDIFF(discharge_ts, admission_ts)) AS total_days
    FROM patient_history
    GROUP BY patient_amka, first_name, last_name, YEAR(admission_ts) /* Ομαδοποίηση και ανά έτος */
)
SELECT *
FROM patient_totals
WHERE total_days > 15
AND (hosp_year, total_days) IN ( /* Έλεγχος σύμπτωσης ημερών ΜΕΣΑ στο ίδιο έτος */
    SELECT hosp_year, total_days
    FROM patient_totals
    GROUP BY hosp_year, total_days
    HAVING COUNT(*) > 1
)
ORDER BY hosp_year, total_days;
