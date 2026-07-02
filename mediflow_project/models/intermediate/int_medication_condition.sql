{{
    config(materialized = 'ephemeral')
}}

{% set medication = ref('stg_raw__medication_request') %}
{% set condition  = ref('stg_raw__condition') %}

{% set configs = [
    {
        'table'  : medication,
        'columns': 'medication.*',
        'alias'  : 'medication'
    },
    {
        'table'  : condition,
        'columns': 'condition.CONDITION_CODE, condition.CONDITION_NAME, condition.CONDITION_SYSTEM, condition.CLINICAL_STATUS',
        'alias'  : 'condition',
        'join_condition': 'medication.ENCOUNTER_ID = condition.ENCOUNTER_ID AND medication.PATIENT_ID = condition.PATIENT_ID'
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