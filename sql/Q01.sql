USE yg_eupolis_hospital;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

WITH hospitalization_days AS (
    SELECT
        h.hosp_id,
        h.patient_amka,
        h.department_id,
        h.ken_code,
        h.admission_ts,
        h.discharge_ts,
        h.total_cost,

        YEAR(h.admission_ts) AS admission_year,

        GREATEST(
            1,
            CEIL(TIMESTAMPDIFF(HOUR, h.admission_ts, h.discharge_ts) / 24)
        ) AS stay_days
    FROM hospitalization h
    WHERE h.discharge_ts IS NOT NULL
),

hospitalization_cost_parts AS (
    SELECT
        hd.hosp_id,
        hd.patient_amka,
        hd.department_id,
        hd.ken_code,
        hd.admission_year,
        hd.stay_days,
        hd.total_cost,

        k.ken_description,
        k.basic_cost,
        k.mean_duration_days,
        k.extra_daily_cost,

        GREATEST(0, hd.stay_days - k.mean_duration_days) AS extra_days,

        k.basic_cost AS calculated_base_cost,

        GREATEST(0, hd.stay_days - k.mean_duration_days) * k.extra_daily_cost
            AS calculated_extra_charge,

        k.basic_cost
        + GREATEST(0, hd.stay_days - k.mean_duration_days) * k.extra_daily_cost
            AS calculated_total_cost
    FROM hospitalization_days hd
    JOIN ken k
        ON k.ken_code = hd.ken_code
)

SELECT
    d.department_name,
    hcp.admission_year,
    hcp.ken_code,
    hcp.ken_description,
    p.insurance_provider,

    COUNT(*) AS total_hospitalizations,

    ROUND(AVG(hcp.stay_days), 2) AS avg_stay_days,
    hcp.mean_duration_days,

    SUM(hcp.extra_days) AS total_extra_days,

    ROUND(SUM(hcp.calculated_base_cost), 2) AS base_revenue,
    ROUND(SUM(hcp.calculated_extra_charge), 2) AS extra_revenue_due_to_mdn_excess,
    ROUND(SUM(hcp.calculated_total_cost), 2) AS calculated_total_revenue,

    ROUND(SUM(hcp.total_cost), 2) AS stored_total_revenue

FROM hospitalization_cost_parts hcp
JOIN department d
    ON d.department_id = hcp.department_id
JOIN patient p
    ON p.patient_amka = hcp.patient_amka

GROUP BY
    d.department_name,
    hcp.admission_year,
    hcp.ken_code,
    hcp.ken_description,
    p.insurance_provider,
    hcp.mean_duration_days

ORDER BY
    hcp.admission_year,
    d.department_name,
    calculated_total_revenue DESC,
    hcp.ken_code,
    p.insurance_provider;
