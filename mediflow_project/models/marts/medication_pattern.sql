--Mart 4 — Medication Patterns
--Business question asked:
--"What are the most commonly prescribed medications for each diagnosed condition, and how would this inform formulary decisions?"
WITH base AS
(
SELECT MEDICATION_NAME,
       CONDITION_NAME,
       PATIENT_ID
FROM {{ ref("int_medication_condition") }}
),
agg AS
(
SELECT MEDICATION_NAME,
       CONDITION_NAME,
       COUNT(*) AS TOTAL_PRESCRIPTIONS,
       COUNT(DISTINCT PATIENT_ID) AS PATIENTS_COUNT
FROM base 
GROUP BY 1,2
),
ranked AS
(
SELECT MEDICATION_NAME,
       CONDITION_NAME,
       PATIENTS_COUNT,
       TOTAL_PRESCRIPTIONS,
       RANK() OVER (PARTITION BY CONDITION_NAME ORDER BY TOTAL_PRESCRIPTIONS DESC) AS RN
FROM agg
),
final AS 
( 
SELECT MEDICATION_NAME,
       CONDITION_NAME,
       PATIENTS_COUNT,
       TOTAL_PRESCRIPTIONS,
       RN
FROM ranked
)
SELECT * FROM final
ORDER BY RN








