SELECT ev.emergency_level, 
    (SELECT AVG(TIMESTAMPDIFF(MINUTE, ev2.arrival_ts, ev2.service_start_ts)) 
     FROM emergency_visit ev2 
     WHERE ev2.emergency_level = ev.emergency_level) AS average_waiting_time, COUNT(*) AS cases_per_department,
    (SELECT 100.0 * SUM(CASE WHEN ev3.disposition = 'HOSPITALIZED' THEN 1 ELSE 0 END) / COUNT(*) 
     FROM emergency_visit ev3 
     WHERE ev3.emergency_level = ev.emergency_level) AS hospitalization_percent,
    
    CASE
        WHEN ev.referred_department_id IS NULL THEN 'No referred department'
        ELSE d.department_name
    END AS department_name
FROM emergency_visit ev
LEFT JOIN department d ON d.department_id = ev.referred_department_id
GROUP BY 
    ev.emergency_level, ev.referred_department_id, d.department_name
ORDER BY ev.emergency_level ASC;
