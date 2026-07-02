{{
    config(materialized = 'ephemeral')
}}

{% set encounter  = ref('stg_raw__encounter') %}
{% set claim      = ref('stg_raw__claim') %}
{% set procedure  = ref('stg_raw__procedure') %}

{% set configs = [
    {
        'table'  : encounter,
        'columns': 'encounter.*',
        'alias'  : 'encounter'
    },
    {
        'table'  : claim,
        'columns': 'claim.CLAIM_ID, claim.STATUS, claim.CLAIM_TYPE, claim.PAYER, claim.TOTAL_AMOUNT, claim.SERVICE_CODE, claim.SERVICE_DESC, claim.CREATED_DATE',
        'alias'  : 'claim',
        'join_condition': 'encounter.ENCOUNTER_ID = claim.ENCOUNTER_ID'
    },
    {
        'table'  : procedure,
        'columns': 'procedure.PROCEDURE_CODE, procedure.PROCEDURE_NAME, procedure.PROCEDURE_SYSTEM, procedure.PERFORMED_START, procedure.PERFORMED_END',
        'alias'  : 'procedure',
        'join_condition': 'encounter.ENCOUNTER_ID = procedure.ENCOUNTER_ID'
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