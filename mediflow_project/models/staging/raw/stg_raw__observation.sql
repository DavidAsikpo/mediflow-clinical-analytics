{{ config(
    materialized         = 'incremental',
    incremental_strategy = 'merge',
    unique_key           = 'OBSERVATION_ID'
) }}

{% set incremental_col = 'EFFECTIVE_DATE' %}

SELECT
    CAST(TRIM(OBSERVATION_ID) AS VARCHAR)                       AS OBSERVATION_ID,
    CAST(TRIM(PATIENT_ID)     AS VARCHAR)                       AS PATIENT_ID,
    CAST(TRIM(ENCOUNTER_ID)   AS VARCHAR)                       AS ENCOUNTER_ID,
    CAST(TRIM(STATUS)         AS VARCHAR)                       AS STATUS,

    CASE
        WHEN REGEXP_LIKE(TRIM(OBS_CODE), '^[0-9]+-[0-9]+$')
        THEN CAST(TRIM(OBS_CODE) AS VARCHAR)
        ELSE NULL
    END                                                         AS OBS_CODE,

    CAST(TRIM(OBS_SYSTEM) AS VARCHAR)                           AS OBS_SYSTEM,
    CAST(REPLACE(TRIM(OBS_NAME), '"', '') AS VARCHAR)           AS OBS_NAME,

    TRY_CAST(REPLACE(TRIM(EFFECTIVE_DATE), '"', '')
        AS TIMESTAMP_NTZ)                                       AS EFFECTIVE_DATE,

    CASE
        WHEN REGEXP_LIKE(TRIM(VALUE), '^[0-9]+(\.[0-9]+)?$')
        THEN TRY_CAST(VALUE AS FLOAT)
        ELSE NULL
    END                                                         AS VALUE,

    CASE
        WHEN REGEXP_LIKE(TRIM(UNIT), '^[a-zA-Z%/{]+$')
        THEN CAST(TRIM(UNIT) AS VARCHAR)
        ELSE NULL
    END                                                         AS UNIT

FROM {{ source('RAW', 'observation') }}

{% if is_incremental() %}
WHERE {{ incremental_col }} > (
    SELECT COALESCE(MAX({{ incremental_col }}), '1900-01-01')
    FROM {{ this }}
)
{% endif %}