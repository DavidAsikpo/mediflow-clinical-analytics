{{
    config(
        materialized = 'table',
        schema       = 'mart'
    )
}}

{% set encounter_stage = ref('encounter_stage') %}
{% set patient_stage  = ref('patient_stage') %}


{% set configs = [ { 
                     'table' : encounter_stage, 
                      'columns': 'encounter_stage.*',
                     'alias': 'encounter_stage'
                   },
                   {
                     'table' : patient_stage, 
                     'columns':'patient_stage.FIRST_NAME,patient_stage.LAST_NAME, patient_stage.GENDER, patient_stage.BIRTH_DATE, patient_stage.AGE,patient_stage.RACE, patient_stage.ETHNICITY, patient_stage.BIRTH_PLACE, patient_stage.CITY, patient_stage.POSTAL_CODE, patient_stage.COUNTRY, patient_stage.MARITAL_STATUS',
                     'alias': 'patient_stage',
                     'join_condition': 'encounter_stage.PATIENT_ID = patient_stage.PATIENT_ID'
                   }

                 ]
%}


WITH joined as (
    SELECT 
    {% for config in configs %}
    {{ config.columns }}{% if not loop.last %},{% endif %}
    {% endfor %}
    FROM 
    {% for config in configs %}
    {% if loop.first %}
    {{ config.table }} AS {{ config.alias }}
    {% else %}
    LEFT JOIN {{ config.table }} AS {{ config.alias }} ON {{ config.join_condition }}
    {% endif %}
    {% endfor %}
), 
aggregation as 
(
    SELECT * ,
          ROW_NUMBER() OVER (
            PARTITION BY PATIENT_ID
            ORDER BY START_DATE
          ) AS encounter_rank,
           LAG(START_DATE) OVER (
            PARTITION BY patient_id
            ORDER BY START_DATE
        ) AS previous_encounter,
        DATEDIFF('day', LAG(START_DATE) OVER (
            PARTITION BY patient_id
            ORDER BY START_DATE), START_DATE) AS days_since_last_encounter,
        {{ re_admission('START_DATE', 'PATIENT_ID',30) }} AS READMISSION
    FROM joined
), 
final as 
( SELECT *,
        {{ surrogate_key(['ENCOUNTER_ID', 'PATIENT_ID']) }} as READMISSION_ID,
        {{ age_bucket('AGE') }} as AGE_GROUP
 FROM aggregation
)  
SELECT * FROM final


