WITH RECURSIVE sup_hierarchy AS (
    SELECT d.amka, d.supervisor_amka, d.doctor_rank, p.first_name, p.last_name, 1 AS lvl
    FROM doctor d
    JOIN personnel p ON d.amka = p.amka
    UNION ALL

    SELECT sh.amka, doc.supervisor_amka, sh.doctor_rank, sh.first_name, sh.last_name, sh.lvl + 1 AS lvl
    FROM sup_hierarchy sh
    JOIN doctor doc ON sh.supervisor_amka = doc.amka
)
SELECT
    s.amka,
    s.supervisor_amka,
    s.doctor_rank,
    s.first_name,
    s.last_name,
    p2.first_name AS supervisor_first_name,
    p2.last_name AS supervisor_last_name,
    s.lvl AS level
FROM sup_hierarchy s
LEFT JOIN personnel p2 ON p2.amka = s.supervisor_amka
ORDER BY s.amka, s.lvl;
