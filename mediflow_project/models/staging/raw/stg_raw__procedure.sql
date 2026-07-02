{{ config(
    materialized         = 'incremental',
    incremental_strategy = 'merge',
    unique_key           = 'PROCEDURE_ID'
) }}

{% set incremental_col = 'PERFORMED_START' %}

SELECT
    CAST(TRIM(PROCEDURE_ID)  AS VARCHAR)                        AS PROCEDURE_ID,
    CAST(TRIM(PATIENT_ID)    AS VARCHAR)                        AS PATIENT_ID,
    CAST(TRIM(ENCOUNTER_ID)  AS VARCHAR)                        AS ENCOUNTER_ID,
    CAST(TRIM(STATUS)        AS VARCHAR)                        AS STATUS,
    CAST(TRIM(PROCEDURE_CODE) AS VARCHAR)                       AS PROCEDURE_CODE,
    CAST(REPLACE(TRIM(PROCEDURE_SYSTEM), '"', '') AS VARCHAR)   AS PROCEDURE_SYSTEM,
    CAST(REPLACE(TRIM(PROCEDURE_NAME),   '"', '') AS VARCHAR)   AS PROCEDURE_NAME,
    TRY_CAST(PERFORMED_START AS TIMESTAMP_NTZ)                  AS PERFORMED_START,
    TRY_CAST(PERFORMED_END   AS TIMESTAMP_NTZ)                  AS PERFORMED_END

FROM {{ source('RAW', 'procedure') }}

{% if is_incremental() %}
WHERE {{ incremental_col }} > (
    SELECT COALESCE(MAX({{ incremental_col }}), '1900-01-01')
    FROM {{ this }}
)
{% endif %}