{{ config(
    materialized         = 'incremental',
    incremental_strategy = 'merge',
    unique_key           = 'CLAIM_ID'
) }}

{% set incremental_col = 'CREATED_DATE' %}

SELECT
    CAST(TRIM(CLAIM_ID)    AS VARCHAR)                          AS CLAIM_ID,
    CAST(TRIM(PATIENT_ID)  AS VARCHAR)                          AS PATIENT_ID,
    CAST(TRIM(ENCOUNTER_ID) AS VARCHAR)                         AS ENCOUNTER_ID,
    CAST(TRIM(STATUS)      AS VARCHAR)                          AS STATUS,
    CAST(TRIM(CLAIM_TYPE)  AS VARCHAR)                          AS CLAIM_TYPE,
    CAST(REPLACE(TRIM(PROVIDER_NAME), '"', '') AS VARCHAR)      AS PROVIDER_NAME,
    CAST(REPLACE(TRIM(PAYER), '"', '') AS VARCHAR)              AS PAYER,
    TRY_CAST(REPLACE(TRIM(CREATED_DATE), '"', '') AS TIMESTAMP_NTZ)
                                                                AS CREATED_DATE,
    TRY_CAST(TOTAL_AMOUNT AS FLOAT)                             AS TOTAL_AMOUNT,
    CAST(TRIM(CURRENCY)    AS VARCHAR)                          AS CURRENCY,
    CAST(TRIM(SERVICE_CODE) AS VARCHAR)                         AS SERVICE_CODE,

    CASE
        WHEN REGEXP_LIKE(SERVICE_DESC, '^[a-zA-Z()/'' ]+$')
        THEN CAST(TRIM(SERVICE_DESC) AS VARCHAR)
        ELSE NULL
    END                                                         AS SERVICE_DESC

FROM {{ source('RAW', 'claim') }}

{% if is_incremental() %}
WHERE {{ incremental_col }} > (
    SELECT COALESCE(MAX({{ incremental_col }}), '1900-01-01')
    FROM {{ this }}
)
{% endif %}