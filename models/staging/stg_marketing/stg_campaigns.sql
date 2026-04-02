with campaigns as(
select * from {{ postgres_source('raw', 'campaigns') }}
),
cleaned as(
SELECT
    id,
    TRIM(name)                      AS name,
    TRIM(LOWER(type))               AS type,
    TRIM(LOWER(channel))            AS channel,
    budget,
    spend_actual,
    start_date,
    end_date,
    TRIM(LOWER(status))             AS status,
    created_at,

    budget IS NULL                  AS is_budget_null,
    (end_date < start_date)         AS is_date_broken,

    CASE
        WHEN budget > 0
        THEN ROUND(spend_actual / budget * 100, 1)
        ELSE NULL
    END                             AS spend_pct
FROM campaigns)

select * from cleaned