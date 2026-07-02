{{ config(
    materialized         = 'incremental',
    incremental_strategy = 'merge',
    unique_key           = 'MEDICATION_ID'
) }}

{% set incremental_col = 'AUTHORED_DATE' %}

SELECT
    CAST(TRIM(MEDICATION_ID)  AS VARCHAR)                       AS MEDICATION_ID,
    CAST(TRIM(PATIENT_ID)     AS VARCHAR)                       AS PATIENT_ID,
    CAST(TRIM(ENCOUNTER_ID)   AS VARCHAR)                       AS ENCOUNTER_ID,
    CAST(TRIM(STATUS)         AS VARCHAR)                       AS STATUS,
    CAST(TRIM(MEDICATION_CODE) AS VARCHAR)                      AS MEDICATION_CODE,
    CAST(REPLACE(TRIM(MEDICATION_NAME), '"', '') AS VARCHAR)    AS MEDICATION_NAME,
    TRY_CAST(TRIM(AUTHORED_DATE) AS TIMESTAMP_NTZ)             AS AUTHORED_DATE,

    CASE
        WHEN REGEXP_LIKE(REQUESTER, '^(DR\.|Dr\.)?[a-zA-Z0-9()/'' ]+$')
        THEN CAST(TRIM(REQUESTER) AS VARCHAR)
        ELSE NULL
    END                                                         AS REQUESTER

FROM {{ source('RAW', 'medication_request') }}

{% if is_incremental() %}
WHERE {{ incremental_col }} > (
    SELECT COALESCE(MAX({{ incremental_col }}), '1900-01-01')
    FROM {{ this }}
)
{% endif %}