SELECT emergency_level, AVG(TIMESTAMPDIFF(MINUTE, arrival_ts, service_start_ts)) AS average_waiting_time,
    COUNT(*) AS cases,  100.0 * SUM(CASE WHEN disposition = 'HOSPITALIZED' THEN 1 ELSE 0 END) / COUNT(*) AS hospitalization_percent,
    COALESCE(d.department_name, 'No referred department') AS department_name
FROM emergency_visit ev
LEFT JOIN department d ON d.department_id = ev.referred_department_id
GROUP BY emergency_level, COALESCE(d.department_name, 'No referred department')
ORDER BY emergency_level ASC;
