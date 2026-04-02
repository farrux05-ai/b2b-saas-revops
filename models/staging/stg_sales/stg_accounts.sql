WITH accounts as (
SELECT * FROM {{ postgres_source('raw', 'accounts') }}
),
cleaned as (
    SELECT
    id,
    TRIM(name)                      AS name,
    TRIM(LOWER(domain))             AS domain,
    TRIM(LOWER(industry))           AS industry,
    employee_count,
    TRIM(UPPER(country))            AS country,
    website,
    owner_id,
    created_at,

    industry IS NULL                AS is_industry_null,
    website IS NULL                 AS is_website_null,
    owner_id IS NULL                AS is_owner_null
FROM accounts
)
select * from cleaned