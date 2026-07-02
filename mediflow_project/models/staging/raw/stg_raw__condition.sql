{{ config(
    materialized         = 'incremental',
    incremental_strategy = 'merge',
    unique_key           = 'CONDITION_ID'
) }}

{% set incremental_col = 'RECORDED_DATE' %}

SELECT
    CAST(TRIM(CONDITION_ID)     AS VARCHAR)     AS CONDITION_ID,
    CAST(TRIM(PATIENT_ID)       AS VARCHAR)     AS PATIENT_ID,
    CAST(TRIM(ENCOUNTER_ID)     AS VARCHAR)     AS ENCOUNTER_ID,
    CAST(TRIM(CLINICAL_STATUS)  AS VARCHAR)     AS CLINICAL_STATUS,
    CAST(TRIM(CONDITION_CODE)   AS VARCHAR)     AS CONDITION_CODE,
    CAST(TRIM(CONDITION_SYSTEM) AS VARCHAR)     AS CONDITION_SYSTEM,
    CAST(TRIM(CONDITION_NAME)   AS VARCHAR)     AS CONDITION_NAME,
    TRY_CAST(TRIM(ONSET_DATE)    AS TIMESTAMP_NTZ)  AS ONSET_DATE,
    TRY_CAST(TRIM(RECORDED_DATE) AS TIMESTAMP_NTZ)  AS RECORDED_DATE

FROM {{ source('RAW', 'condition') }}

{% if is_incremental() %}
WHERE {{ incremental_col }} > (
    SELECT COALESCE(MAX({{ incremental_col }}), '1900-01-01')
    FROM {{ this }}
)
{% endif %}