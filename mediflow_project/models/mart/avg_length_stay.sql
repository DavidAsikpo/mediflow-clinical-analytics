{% set encounter_stage = ref('encounter_stage') %}
{% set condition_stage =  ref('condition_stage')  %}


{% set configs = [ {  
                 'table': encounter_stage,
                 'columns': 'encounter_stage.*',
                 'alias': 'encounter_stage'
                },
                {
                 'table': condition_stage,
                 'columns': 'condition_stage.CONDITION_NAME',
                 'alias': 'condition_stage',
                 'join_condition': 'encounter_stage.PATIENT_ID = condition_stage.PATIENT_ID'


                }


              ]
%}

with joined AS (
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
{% endfor %}), base AS (
    SELECT ENCOUNTER_TYPE,
           CONDITION_NAME,
           DATEDIFF('minutes', START_DATE, END_DATE) AS LOS_minutes
    FROM joined)
SELECT   {{ surrogate_key(['ENCOUNTER_TYPE', 'CONDITION_NAME']) }} AS LOS_ID,
         ENCOUNTER_TYPE,
         CONDITION_NAME,
         AVG(LOS_MINUTES) AS AVG_LOS_MINUTES
FROM base
GROUP BY 1, 2


