WITH yearly_admissions AS (
    SELECT icd10_code, icd10_description, YEAR(admission_ts) AS yr, COUNT(*) AS admissions
    FROM patient_history
    GROUP BY icd10_code, icd10_description, YEAR(admission_ts)
    HAVING COUNT(*) >= 5
)
SELECT y1.icd10_code, y1.icd10_description, y1.yr AS yr1, y2.yr AS yr2, y1.admissions
FROM yearly_admissions y1
JOIN yearly_admissions y2 ON y1.icd10_code = y2.icd10_code
    AND y1.yr = y2.yr + 1
    AND y1.admissions = y2.admissions;
