{% macro age_bucket(column) %}

    CASE
        WHEN {{ column }} < 18  THEN '0-17'
        WHEN {{ column }} < 35  THEN '18-34'
        WHEN {{ column }} < 55  THEN '35-54'
        WHEN {{ column }} < 75  THEN '55-74'
        ELSE '75+'
    END

{% endmacro %}