
  
  create view "revops_analytics"."revops_staging"."stg_campaign_members__dbt_tmp" as (
    WITH campaign_members as(
SELECT * FROM postgres_scan(
  'dbname=revops_database user=farrux password=farrux05 host=localhost port=5432',
  'raw',
  'campaign_members'
)
),
cleaned as(
SELECT
    id,
    lead_id,
    campaign_id,
    first_touch_at,
    last_touch_at,
    responded,
    converted,
    created_at,

    (last_touch_at < first_touch_at) AS is_touch_date_broken
FROM campaign_members)
select * from cleaned
  );
