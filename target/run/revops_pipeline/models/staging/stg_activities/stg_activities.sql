
  
  create view "revops_analytics"."revops_staging"."stg_activities__dbt_tmp" as (
    with activities as (
    select * from postgres_scan(
  'dbname=revops_database user=farrux password=farrux05 host=localhost port=5432',
  'raw',
  'activities'
)
),
cleaned as (
    SELECT
    id,
    contact_id,
    opportunity_id,
    TRIM(LOWER(type))               AS type,
    subject,
    occurred_at,
    owner_id,

    type IS NULL                    AS is_type_null,
    occurred_at IS NULL             AS is_date_null
from activities
)
select * from cleaned
  );
