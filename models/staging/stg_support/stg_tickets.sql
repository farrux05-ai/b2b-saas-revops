WITH tickets as (
    select * from {{ postgres_source('raw', 'tickets') }}
),
cleaned as(
    SELECT
    id,
    account_id,
    contact_id,
    subject,
    TRIM(LOWER(status))             AS status,
    TRIM(LOWER(priority))           AS priority,
    TRIM(LOWER(category))           AS category,
    created_at,
    first_response_at,
    solved_at,
    agent_id,

    category IS NULL                AS is_category_null,
    agent_id IS NULL                AS is_agent_null,
    first_response_at IS NULL       AS is_no_response,

    (status IN ('solved','closed')
     AND solved_at IS NULL)         AS is_solved_date_missing,

    CASE
        WHEN first_response_at IS NOT NULL
        THEN EXTRACT(EPOCH FROM
             (first_response_at - created_at))/3600
        ELSE NULL
    END                             AS hours_to_first_response,

    ROW_NUMBER() OVER (
        PARTITION BY account_id, subject, status
        ORDER BY created_at ASC
    )                               AS ticket_row_num
from tickets
)
select * from cleaned