with product_companies as (
    select * from {{ postgres_source('raw', 'product_companies') }}
),
cleaned as(
    SELECT
    id,
    account_id,
    TRIM(name)                      AS name,
    TRIM(LOWER(plan))               AS plan,
    seat_count,

    plan IS NULL                    AS is_plan_null,
    seat_count IS NULL              AS is_seat_null,
    account_id IS NULL              AS is_account_unlinked
from product_companies
)
select * from cleaned