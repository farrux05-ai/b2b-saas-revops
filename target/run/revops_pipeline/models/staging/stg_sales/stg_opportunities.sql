
  
  create view "revops_analytics"."revops_staging"."stg_opportunities__dbt_tmp" as (
    with opportunities as (
    SELECT * FROM postgres_scan(
  'dbname=revops_database user=farrux password=farrux05 host=localhost port=5432',
  'raw',
  'opportunities'
)
),
cleaned as (
SELECT
    id,
    account_id,
    contact_id,
    lead_id,
    TRIM(name)                      AS name,
    TRIM(LOWER(stage))              AS stage,
    amount,
    close_date,
    owner_id,
    created_at,

    amount IS NULL                  AS is_amount_null,
    owner_id IS NULL                AS is_owner_null,
    (close_date < CURRENT_DATE
     AND stage NOT IN
         ('closed_won','closed_lost')) AS is_close_date_past
from opportunities)
select * from cleaned
  );
