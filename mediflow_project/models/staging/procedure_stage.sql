{{ config(materialized = 'incremental') }}
{% set incremental_col = 'PERFORMED_START' %}


SELECT * FROM {{ ref('procedure_clean') }}
{% if is_incremental() %}
WHERE {{ incremental_col }} > (SELECT COALESCE(MAX({{ incremental_col }}), '1900-01-01') FROM {{ this }})
{% endif %}