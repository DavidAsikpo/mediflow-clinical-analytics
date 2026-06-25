{% set condition_stage = ref('condition_stage') %}
{% set patient_stage =  ref('patient_stage')  %}


{% set configs = [ {  
                 'table': condition_stage,
                 'columns': 'condition_stage.*',
                 'alias': 'condition_stage'
                },
                {
                 'table': patient_stage,
                 'columns': 'patient_stage.AGE, patient_stage.RACE, patient_stage.GENDER',
                 'alias': 'patient_stage',
                 'join_condition': 'condition_stage.PATIENT_ID = patient_stage.PATIENT_ID'


                }


              ]
%}

WITH joined AS (
SELECT 
{% for config in configs %}
{{ config.columns }}{% if not loop.last %},{% endif %}
{% endfor %}
FROM
{% for config in configs %}
{% if loop.first %}{{ config.table }} AS {{ config.alias }}
{% else %}
LEFT JOIN {{ config.table }} AS  {{ config.alias }} ON  {{ config.join_condition }}
{% endif %}
{% endfor %}),

age_group AS( 
    SELECT CONDITION_ID,
           PATIENT_ID,
           ENCOUNTER_ID,
           CLINICAL_STATUS,
           CONDITION_CODE,
           CONDITION_SYSTEM,
           CONDITION_NAME,
           ONSET_DATE,
           RECORDED_DATE,
           AGE,
           {{ age_bucket('AGE') }} AS AGE_GROUP,
           RACE,
           GENDER,
           COUNT(*)
    FROM joined
) SELECT * FROM age_group

