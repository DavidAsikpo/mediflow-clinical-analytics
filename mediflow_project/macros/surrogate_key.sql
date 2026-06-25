{% macro surrogate_key(columns) %}

    MD5(
        {%- for col in columns %}
            COALESCE(CAST({{ col }} AS VARCHAR), 'NULL')
            {%- if not loop.last %} || '-' || {% endif %}
        {%- endfor %}
    )

{% endmacro %}