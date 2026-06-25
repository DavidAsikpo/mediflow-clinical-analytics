{{ config(materialized = 'incremental') }}
{% set incremental_col = 'EFFECTIVE_DATE' %}


SELECT * FROM {{ ref('observation_clean') }}
{% if is_incremental() %}
WHERE {{ incremental_col }} > (SELECT COALESCE(MAX({{ incremental_col }}), '1900-01-01') FROM {{ this }})
{% endif %}