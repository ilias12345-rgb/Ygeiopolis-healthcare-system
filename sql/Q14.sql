USE ygeiopolis;
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;

/* Q14: ICD-10 categories with the same admission count in consecutive years.*/
WITH yearly_admissions AS (
    /* Compare ICD-10 categories, using the first three characters of the code. */
    SELECT LEFT(icd10_code, 3) AS icd10_category, YEAR(admission_ts) AS yr, COUNT(*) AS admissions
    FROM patient_history
    GROUP BY LEFT(icd10_code, 3), YEAR(admission_ts)
    HAVING COUNT(*) >= 5
)
SELECT y1.icd10_category, y1.yr AS year1, y2.yr AS year2, y1.admissions
FROM yearly_admissions y1
JOIN yearly_admissions y2 ON y1.icd10_category = y2.icd10_category
    AND y1.yr = y2.yr + 1
    AND y1.admissions = y2.admissions;
