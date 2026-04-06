
  
  create view "revops_analytics"."revops_staging"."stg_accounts__dbt_tmp" as (
    WITH accounts as (
SELECT * FROM postgres_scan(
  'dbname=revops_database user=farrux password=farrux05 host=localhost port=5432',
  'raw',
  'accounts'
)
),
cleaned as (
    SELECT
    id,
    TRIM(name)                      AS name,
    TRIM(LOWER(domain))             AS domain,
    TRIM(LOWER(industry))           AS industry,
    employee_count,
    TRIM(UPPER(country))            AS country,
    website,
    owner_id,
    created_at,

    industry IS NULL                AS is_industry_null,
    website IS NULL                 AS is_website_null,
    owner_id IS NULL                AS is_owner_null
FROM accounts
)
select * from cleaned
  );
