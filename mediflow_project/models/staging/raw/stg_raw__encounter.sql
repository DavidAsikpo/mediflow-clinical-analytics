{{ config(
    materialized         = 'incremental',
    incremental_strategy = 'merge',
    unique_key           = 'ENCOUNTER_ID'
) }}

{% set incremental_col = 'START_DATE' %}

SELECT
    CAST(TRIM(ENCOUNTER_ID)  AS VARCHAR)                        AS ENCOUNTER_ID,
    CAST(TRIM(PATIENT_ID)    AS VARCHAR)                        AS PATIENT_ID,
    CAST(TRIM(STATUS)        AS VARCHAR)                        AS STATUS,
    CAST(TRIM(CLASS_CODE)    AS VARCHAR)                        AS CLASS_CODE,
    CAST(TRIM(ENCOUNTER_TYPE) AS VARCHAR)                       AS ENCOUNTER_TYPE,
    TRY_CAST(TRIM(START_DATE) AS TIMESTAMP_NTZ)                AS START_DATE,
    TRY_CAST(TRIM(END_DATE)   AS TIMESTAMP_NTZ)                AS END_DATE,
    CAST(REPLACE(TRIM(PROVIDER_NAME), '"', '') AS VARCHAR)      AS PROVIDER_NAME,

    CASE
        WHEN REGEXP_LIKE(PRACTITIONER, '^(DR\.|Dr\.)?[a-zA-Z0-9()/'' ]+$')
        THEN CAST(TRIM(PRACTITIONER) AS VARCHAR)
        ELSE NULL
    END                                                         AS PRACTITIONER

FROM {{ source('RAW', 'encounter') }}

{% if is_incremental() %}
WHERE {{ incremental_col }} > (
    SELECT COALESCE(MAX({{ incremental_col }}), '1900-01-01')
    FROM {{ this }}
)
{% endif %}