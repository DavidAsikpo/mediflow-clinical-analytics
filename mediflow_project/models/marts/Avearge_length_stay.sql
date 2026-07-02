--Mart 3 — Average Length of Stay
--Business question asked:
--"How long are patients staying for different types of encounters and diagnoses, and where do we see unusual variability?"

with base as
(
SELECT ENCOUNTER_TYPE,
        CONDITION_NAME,
        DATEDIFF('minute', START_DATE, END_DATE) AS LENGTH_OF_STAY
        FROM {{ ref('int_encounter_condition') }}
),
aggregation as 
(
SELECT ENCOUNTER_TYPE,
       CONDITION_NAME,
       COUNT(*) AS T0TAL_ENCOUNTERS,
       AVG(LENGTH_OF_STAY) AS MEAN_STAY,
       PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY LENGTH_OF_STAY) as MEDIAN_STAY,
       MIN(LENGTH_OF_STAY) AS MIN_STAY,
       MAX(LENGTH_OF_STAY) AS MAX_STAY,
       ROUND(STDDEV(LENGTH_OF_STAY), 2) AS STDDEV_STAY 
FROM base 
GROUP BY ENCOUNTER_TYPE, CONDITION_NAME
),
mode_calc as
(
SELECT ROW_NUMBER() OVER (PARTITION BY ENCOUNTER_TYPE, CONDITION_NAME ORDER BY  COUNT(*)) AS RN,
       ENCOUNTER_TYPE,
       CONDITION_NAME,
       LENGTH_OF_STAY
FROM base
GROUP BY ENCOUNTER_TYPE, CONDITION_NAME, LENGTH_OF_STAY
),
mode_only as
( 
SELECT ENCOUNTER_TYPE,
       CONDITION_NAME,
       LENGTH_OF_STAY AS MODE_STAY
FROM mode_calc
WHERE RN = 1
),
final as 
(
SELECT A.ENCOUNTER_TYPE,
       A.CONDITION_NAME,
       B.MODE_STAY,
       A.MEDIAN_STAY,
       A.MEAN_STAY,
       A.MIN_STAY,
       A.MAX_STAY,
       A.STDDEV_STAY 
FROM aggregation AS A
LEFT JOIN mode_only AS B ON A.ENCOUNTER_TYPE = B.ENCOUNTER_TYPE AND A.CONDITION_NAME = B.CONDITION_NAME
)
SELECT * FROM final
ORDER BY MEAN_STAY DESC
       


