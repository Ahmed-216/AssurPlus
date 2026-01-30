{% test no_duplicates(model, column_name) %}

  SELECT 
    {{ column_name }},
    COUNT(*) AS duplicate_count
  FROM {{ model }}
  WHERE {{ column_name }} IS NOT NULL AND {{ column_name }} != ''
  GROUP BY {{ column_name }}
  HAVING COUNT(*) > 1

{% endtest %}
