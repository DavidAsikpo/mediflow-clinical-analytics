{% macro re_admission(date_col, patient_col, days=30) %}

    CASE
        WHEN DATEDIFF('day',
            LAG({{ date_col }}) OVER (PARTITION BY {{ patient_col }} ORDER BY {{ date_col }}),
            {{ date_col }}
        ) <= {{ days }} THEN TRUE
        ELSE FALSE
    END

{% endmacro %}