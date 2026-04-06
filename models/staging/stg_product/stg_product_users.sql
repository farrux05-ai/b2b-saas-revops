with product_users as (
    SELECT * from {{ postgres_source('raw', 'product_users') }}
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

    -- Flag users who have no signup timestamp (incomplete onboarding records)
    signed_up_at IS NULL            AS is_signup_null,

    -- Flag users with no activity recorded (never logged in after signup)
    last_seen_at IS NULL            AS is_last_seen_null,

    -- Days elapsed since the user was last active.
    -- Returns NULL when last_seen_at is missing to avoid misleading 0-day values.
    -- Note: ::DATE is DuckDB/Postgres syntax. Use CAST(... AS DATE) if migrating to BigQuery.
    CASE
        WHEN last_seen_at IS NULL THEN NULL
        ELSE (CURRENT_DATE - last_seen_at::DATE)
    END                             AS days_since_seen

from product_users
)
select * from cleaned