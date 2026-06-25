{% macro age_calculate(column) %}
   DATEDIFF('year', {{ column }},  CURRENT_DATE())
{% endmacro %}