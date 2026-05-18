WITH LevelTotals AS (
    SELECT 
        emergency_level,
        COUNT(*) AS total_cases_in_level,
        ROUND(AVG(TIMESTAMPDIFF(MINUTE, arrival_ts, service_start_ts)), 2) AS avg_waiting_time,
        ROUND(100.0 * SUM(CASE WHEN disposition = 'HOSPITALIZED' THEN 1 ELSE 0 END) / COUNT(*), 2) AS hosp_percent
    FROM emergency_visit
    GROUP BY emergency_level
)
SELECT 
    ev.emergency_level, 
    lt.avg_waiting_time AS average_waiting_time, 
    CASE
        WHEN ev.referred_department_id IS NULL THEN 'No referred department'
        ELSE d.department_name
    END AS department_name,
    
    COUNT(*) AS cases_per_department,
    ROUND(100.0 * COUNT(*) / lt.total_cases_in_level, 2) AS department_distribution_percent

FROM emergency_visit ev
LEFT JOIN department d ON d.department_id = ev.referred_department_id
JOIN LevelTotals lt ON ev.emergency_level = lt.emergency_level
GROUP BY 
    ev.emergency_level, 
    lt.avg_waiting_time,
    lt.hosp_percent,
    lt.total_cases_in_level,
    ev.referred_department_id, 
    d.department_name
ORDER BY 
    ev.emergency_level ASC, 
    cases_per_department DESC;
