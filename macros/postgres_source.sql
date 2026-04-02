-- Macro to simplify reading from Postgres in DuckDB
{%- macro postgres_source(schema, table) -%}
postgres_scan(
  'dbname=DB_NAME user=USER_NAAME password=PASSWORD host=localhost port=5432',
  '{{ schema }}',
  '{{ table }}'
)
{%- endmacro -%}

