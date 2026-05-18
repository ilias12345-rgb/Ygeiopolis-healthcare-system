WITH LevelStats AS (
    -- Υπολογισμός των σωστών ποσοστών αυστηρά ΑΝΑ ΕΠΙΠΕΔΟ
    SELECT 
        emergency_level,
        ROUND(AVG(TIMESTAMPDIFF(MINUTE, arrival_ts, service_start_ts)), 2) AS average_waiting_time,
        ROUND(100.0 * SUM(CASE WHEN disposition = 'HOSPITALIZED' THEN 1 ELSE 0 END) / COUNT(*), 2) AS hospitalization_percent
    FROM emergency_visit
    GROUP BY emergency_level
)
SELECT 
    ev.emergency_level, 
    ls.average_waiting_time, -- Σωστός μέσος όρος επιπέδου
    ls.hospitalization_percent, -- Σωστό ποσοστό επιπέδου
    CASE
        WHEN ev.referred_department_id IS NULL THEN 'No referred department'
        ELSE d.department_name
    END AS department_name,
    COUNT(*) AS cases_per_department -- Πόσα περιστατικά πήγαν στο συγκεκριμένο τμήμα
FROM emergency_visit ev
LEFT JOIN department d ON d.department_id = ev.referred_department_id
JOIN LevelStats ls ON ev.emergency_level = ls.emergency_level
GROUP BY 
    ev.emergency_level, 
    ls.average_waiting_time,
    ls.hospitalization_percent,
    ev.referred_department_id, 
    d.department_name
ORDER BY 
    ev.emergency_level ASC, 
    cases_per_department DESC;
