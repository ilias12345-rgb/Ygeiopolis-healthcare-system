SELECT emergency_level, AVG(TIMESTAMPDIFF(MINUTE, arrival_ts, service_start_ts)) AS average_waiting_time, 
    COUNT(*) AS cases,  100.0 * SUM(CASE WHEN disposition = 'HOSPITALIZED' THEN 1 ELSE 0 END) / COUNT(*) AS hospitalization_percent,
    CASE
        WHEN referred_department_id IS NULL
        THEN 'No referred department'
        ELSE d.department_name
    END AS department_name
FROM emergency_visit ev
LEFT JOIN department d ON d.department_id = ev.referred_department_id
GROUP BY emergency_level, d.department_name
ORDER BY emergency_level ASC;
