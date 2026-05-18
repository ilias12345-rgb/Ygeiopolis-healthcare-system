SELECT 
    ev.emergency_level, 
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, ev.arrival_ts, ev.service_start_ts)), 2) AS average_waiting_time, 
    COUNT(*) AS cases_per_department,
    ROUND(100.0 * SUM(CASE WHEN ev.disposition = 'HOSPITALIZED' THEN 1 ELSE 0 END) / COUNT(*), 2) AS hospitalization_percent,
    CASE
        WHEN ev.referred_department_id IS NULL THEN 'No referred department'
        ELSE d.department_name
    END AS department_name
FROM emergency_visit ev
LEFT JOIN department d ON d.department_id = ev.referred_department_id
GROUP BY 
    ev.emergency_level, 
    ev.referred_department_id, 
    d.department_name
ORDER BY 
    ev.emergency_level ASC, 
    cases_per_department DESC;
