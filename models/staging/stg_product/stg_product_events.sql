with product_events as (
    SELECT * from {{ postgres_source('raw', 'product_events') }}
),
cleaned as (
    SELECT
    id,
    user_id,
    company_id,
    TRIM(LOWER(event_name))         AS event_name,
    properties,
    occurred_at,

    occurred_at IS NULL             AS is_date_null,
    properties IS NULL              AS is_properties_null
from product_events
)
select * from cleaned