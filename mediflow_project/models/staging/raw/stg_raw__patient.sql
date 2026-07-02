{{ config(materialized = 'view') }}

SELECT
    CAST(TRIM(PATIENT_ID) AS VARCHAR)                               AS PATIENT_ID,
    CAST(TRIM(REGEXP_REPLACE(FIRST_NAME, '[0-9]+$', '')) AS VARCHAR) AS FIRST_NAME,
    CAST(TRIM(REGEXP_REPLACE(LAST_NAME,  '[0-9]+$', '')) AS VARCHAR) AS LAST_NAME,
    CAST(TRIM(GENDER) AS VARCHAR)                                   AS GENDER,
    TRY_CAST(TRIM(BIRTH_DATE) AS TIMESTAMP_NTZ)                    AS BIRTH_DATE,
    {{ age_calculate('BIRTH_DATE') }}                               AS AGE,
    CAST(TRIM(RACE) AS VARCHAR)                                     AS RACE,
    CAST(TRIM(ETHNICITY) AS VARCHAR)                                AS ETHNICITY,
    CAST(REPLACE(TRIM(BIRTH_PLACE), '"', '') AS VARCHAR)           AS BIRTH_PLACE,
    CAST(TRIM(CITY) AS VARCHAR)                                     AS CITY,
    CAST(TRIM(STATE) AS VARCHAR)                                    AS STATE,
    CAST(TRIM(POSTAL_CODE) AS VARCHAR)                             AS POSTAL_CODE,
    CAST(TRIM(MARITAL_STATUS) AS VARCHAR)                          AS MARITAL_STATUS,
    CAST(TRIM(LANGUAGE) AS VARCHAR)                                AS LANGUAGE

FROM {{ source('RAW', 'patient') }}
