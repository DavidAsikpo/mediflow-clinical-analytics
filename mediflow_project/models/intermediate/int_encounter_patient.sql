{{
    config(materialized = 'ephemeral')
}}

{% set encounter = ref('stg_raw__encounter') %}
{% set patient   = ref('stg_raw__patient') %}

{% set configs = [
    {
        'table'  : encounter,
        'columns': 'encounter.*',
        'alias'  : 'encounter'
    },
    {
        'table'  : patient,
        'columns': 'patient.FIRST_NAME, patient.LAST_NAME, patient.GENDER, patient.AGE, patient.RACE, patient.ETHNICITY, patient.BIRTH_DATE, patient.CITY, patient.POSTAL_CODE, patient.MARITAL_STATUS',
        'alias'  : 'patient',
        'join_condition': 'encounter.PATIENT_ID = patient.PATIENT_ID'
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