
  
  create view "revops_analytics"."revops_staging"."stg_subscriptions__dbt_tmp" as (
    with subscriptions as(
    SELECT * FROM postgres_scan(
  'dbname=revops_database user=farrux password=farrux05 host=localhost port=5432',
  'raw',
  'subscriptions'
)
),
cleaned as(
    SELECT
    id,
    account_id,
    TRIM(LOWER(plan))               AS plan,
    TRIM(LOWER(status))             AS status,
    mrr,
    trial_start,
    trial_end,
    started_at,
    cancelled_at,

    (status = 'active'
     AND cancelled_at IS NOT NULL)  AS is_status_conflict,

    (status = 'past_due')           AS is_past_due,

    (status NOT IN ('trialing','cancelled')
     AND mrr = 0)                   AS is_mrr_zero
from subscriptions
)
select * from cleaned
  );
