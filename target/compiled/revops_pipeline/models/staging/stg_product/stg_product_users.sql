with product_users as (
    SELECT * from postgres_scan(
  'dbname=revops_database user=farrux password=farrux05 host=localhost port=5432',
  'raw',
  'product_users'
)
),
cleaned as(
    SELECT
    id,
    account_id,
    TRIM(LOWER(email))              AS email,
    TRIM(LOWER(role))               AS role,
    TRIM(LOWER(status))             AS status,
    signed_up_at,
    last_seen_at,

    signed_up_at IS NULL            AS is_signup_null,
    last_seen_at IS NULL            AS is_last_seen_null,

    CASE
        WHEN last_seen_at IS NULL THEN NULL
        ELSE (CURRENT_DATE - last_seen_at::DATE)
    END                             AS days_since_seen
from product_users
)
select * from cleaned