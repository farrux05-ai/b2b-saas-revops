
  
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

    -- Data quality flag: status says 'active' but a cancellation date exists.
    -- This is a CRM data entry error. Should be investigated and corrected at source.
    (status = 'active'
     AND cancelled_at IS NOT NULL)  AS is_status_conflict,

    -- Revenue risk flag: subscription is past due.
    -- Accounts with this flag need immediate follow-up from the collections or CSM team.
    (status = 'past_due')           AS is_past_due,

    -- Revenue integrity flag: subscription is active but MRR is zero.
    -- This likely indicates a free plan slipping through, a pricing config bug,
    -- or a manual override. Directly inflates customer count without revenue contribution.
    (status NOT IN ('trialing','cancelled')
     AND mrr = 0)                   AS is_mrr_zero

from subscriptions
)
select * from cleaned
  );
