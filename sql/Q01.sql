USE yg_eupolis_hospital;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Q01: Revenue per department, admission year, KEN, and insurance provider.
SELECT
    d.department_name,
    YEAR(h.admission_ts) AS admission_year,
    h.ken_code,
    k.ken_description,
    p.insurance_provider,

    COUNT(*) AS total_hospitalizations,

    ROUND(AVG(GREATEST(1, CEIL(TIMESTAMPDIFF(HOUR, h.admission_ts, h.discharge_ts) / 24))), 2)
        AS avg_stay_days,
    k.mean_duration_days,

    SUM(GREATEST(
        0,
        GREATEST(1, CEIL(TIMESTAMPDIFF(HOUR, h.admission_ts, h.discharge_ts) / 24))
            - k.mean_duration_days
    )) AS total_extra_days,

    ROUND(SUM(k.basic_cost), 2) AS base_revenue,
    ROUND(SUM(
        GREATEST(
            0,
            GREATEST(1, CEIL(TIMESTAMPDIFF(HOUR, h.admission_ts, h.discharge_ts) / 24))
                - k.mean_duration_days
        ) * k.extra_daily_cost
    ), 2) AS extra_revenue_due_to_mdn_excess,
    ROUND(SUM(
        k.basic_cost
        + GREATEST(
            0,
            GREATEST(1, CEIL(TIMESTAMPDIFF(HOUR, h.admission_ts, h.discharge_ts) / 24))
                - k.mean_duration_days
        ) * k.extra_daily_cost
    ), 2) AS calculated_total_revenue,

    ROUND(SUM(h.total_cost), 2) AS stored_total_revenue

FROM hospitalization h
JOIN department d ON d.department_id = h.department_id
JOIN ken k ON k.ken_code = h.ken_code
JOIN patient p ON p.patient_amka = h.patient_amka
WHERE h.discharge_ts IS NOT NULL

GROUP BY
    d.department_name,
    YEAR(h.admission_ts),
    h.ken_code,
    k.ken_description,
    p.insurance_provider,
    k.mean_duration_days

ORDER BY
    admission_year,
    d.department_name,
    calculated_total_revenue DESC,
    h.ken_code,
    p.insurance_provider;
