-- Macro to simplify reading from Postgres in DuckDB
{%- macro postgres_source(schema, table) -%}
postgres_scan(
  'dbname=revops_database user=farrux password=farrux05 host=localhost port=5432',
  '{{ schema }}',
  '{{ table }}'
)
{%- endmacro -%}

