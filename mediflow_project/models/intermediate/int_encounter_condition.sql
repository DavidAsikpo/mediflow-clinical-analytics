{{
    config(materialized = 'ephemeral')
}}

{% set encounter  = ref('stg_raw__encounter') %}
{% set condition  = ref('stg_raw__condition') %}

{% set configs = [
    {
        'table'  : encounter,
        'columns': 'encounter.*',
        'alias'  : 'encounter'
    },
    {
        'table'  : condition,
        'columns': 'condition.CONDITION_CODE, condition.CONDITION_NAME, condition.CONDITION_SYSTEM, condition.CLINICAL_STATUS, condition.ONSET_DATE, condition.RECORDED_DATE',
        'alias'  : 'condition',
        'join_condition': 'encounter.ENCOUNTER_ID = condition.ENCOUNTER_ID AND encounter.PATIENT_ID = condition.PATIENT_ID'
    }
] %}

SELECT
{% for cfg in configs %}
    {{ cfg.columns }}{% if not loop.last %},{% endif %}
{% endfor %}
FROM
{% for cfg in configs %}
    {% if loop.first %}
        {{ cfg.table }} AS {{ cfg.alias }}
    {% else %}
        LEFT JOIN {{ cfg.table }} AS {{ cfg.alias }}
            ON {{ cfg.join_condition }}
    {% endif %}
{% endfor %}