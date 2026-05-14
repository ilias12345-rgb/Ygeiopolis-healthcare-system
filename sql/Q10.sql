SELECT ps1.substance_id, ps1.substance_name, ps2.substance_id, ps2.substance_name, COUNT(*) AS frequency
FROM prescription_substances ps1
JOIN prescription_substances ps2 ON ps1.hosp_id = ps2.hosp_id
WHERE ps1.substance_id < ps2.substance_id   /*Για αποφυγή διπλότυπων ζευγών (substance1, substance2) (substance2, substance1)*/
GROUP BY ps1.substance_id, ps1.substance_name, ps2.substance_id, ps2.substance_name
ORDER BY frequency DESC
LIMIT 3;
