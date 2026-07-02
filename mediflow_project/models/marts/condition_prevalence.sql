--Mart 2 — Condition Prevalence
--Business question asked:
--"What are the most common health conditions across our patient population, broken down by age_group, gender, and race — and how prevalent is each condition relative to population size?"

WITH demographic_counts AS (
    SELECT 
        age_group,
        gender,
        race,
        COUNT(DISTINCT patient_id) AS total_group_patients
    FROM {{ ref('int_condition_patient') }}
    GROUP BY age_group, gender, race
),

condition_counts AS (
    SELECT 
        condition_name,
        age_group,
        gender,
        race,
        COUNT(DISTINCT patient_id) AS patients_with_condition
    FROM {{ ref('int_condition_patient') }}
    GROUP BY condition_name, age_group, gender, race
)

SELECT 
    c.condition_name,
    c.age_group,
    c.gender,
    c.race,
    c.patients_with_condition,
    d.total_group_patients,
    ROUND(
        (c.patients_with_condition::FLOAT / d.total_group_patients::FLOAT) * 100, 
        2
    ) AS prevalence_percentage
FROM condition_counts c
JOIN demographic_counts d 
  ON c.age_group = d.age_group
 AND c.gender = d.gender
 AND c.race = d.race
ORDER BY c.patients_with_condition DESC