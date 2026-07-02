--Mart 1 — Patient Readmissions
--Business question asked:
--Which patients were readmitted within 30 days of a previous inpatient visit, and what does that tell us about care quality?"

with base AS 
(SELECT PATIENT_ID, 
        ENCOUNTER_ID,
        ENCOUNTER_TYPE, 
        START_DATE,
        LAG(START_DATE) OVER(PARTITION BY PATIENT_ID ORDER BY START_DATE) AS PREVIOUS_VISIT
 FROM {{ ref('int_encounter-claim') }}
)
SELECT  PATIENT_ID, 
        ENCOUNTER_ID,
        ENCOUNTER_TYPE,
        START_DATE, DATEDIFF(day, PREVIOUS_VISIT, START_DATE) AS DAYS_SINCE_LAST_VSIST
FROM base
WHERE PREVIOUS_VISIT IS NOT NULL AND DATEDIFF(day, PREVIOUS_VISIT, START_DATE) < 30

