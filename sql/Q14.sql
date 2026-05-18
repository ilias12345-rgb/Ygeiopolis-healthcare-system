USE yg_eupolis_hospital;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Q14: Diagnoses with the same admission count in consecutive years.
WITH yearly_admissions AS (
    -- Count each diagnosis per admission year before comparing consecutive years.
    SELECT icd10_code, icd10_description, YEAR(admission_ts) AS yr, COUNT(*) AS admissions
    FROM patient_history
    GROUP BY icd10_code, icd10_description, YEAR(admission_ts)
    HAVING COUNT(*) >= 5
)
SELECT y1.icd10_code, y1.icd10_description, y1.yr AS year1, y2.yr AS year2, y1.admissions
FROM yearly_admissions y1
JOIN yearly_admissions y2 ON y1.icd10_code = y2.icd10_code
    AND y1.yr = y2.yr + 1
    AND y1.admissions = y2.admissions;
