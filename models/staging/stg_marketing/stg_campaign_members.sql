WITH campaign_members as(
SELECT * FROM {{ postgres_source('raw', 'campaign_members') }}
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