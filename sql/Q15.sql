SELECT 
    ev.emergency_level, 
    COUNT(*) AS total_cases,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, ev.arrival_ts, ev.service_start_ts)), 2) AS average_waiting_time, 
    ROUND(100.0 * SUM(CASE WHEN ev.disposition = 'HOSPITALIZED' THEN 1 ELSE 0 END) / COUNT(*), 2) AS hospitalization_percent
FROM emergency_visit ev
GROUP BY ev.emergency_level
ORDER BY ev.emergency_level ASC;

/*========================================================================================*/
SELECT 
    CASE
        WHEN ev.referred_department_id IS NULL THEN 'No referred department'
        ELSE d.department_name
    END AS department_name,
    COUNT(*) AS total_referrals,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM emergency_visit), 2) AS referral_percentage
FROM emergency_visit ev
LEFT JOIN department d ON d.department_id = ev.referred_department_id
GROUP BY ev.referred_department_id, d.department_name
ORDER BY total_referrals DESC;
