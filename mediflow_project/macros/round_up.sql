{% macro round_up(column_name, decimal_places) %}

         ROUND({{ column_name }}, {{ decimal_places }})
{% endmacro %}