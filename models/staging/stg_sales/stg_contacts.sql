WITH contacts as (
SELECT * FROM {{ postgres_source('raw', 'contacts') }}
),
cleaned as (
    SELECT
    id,
    account_id,
    lead_id,
    TRIM(LOWER(email))              AS email,
    TRIM(first_name)                AS first_name,
    TRIM(last_name)                 AS last_name,
    TRIM(job_title)                 AS job_title,
    is_primary,
    created_at,

    lead_id IS NULL                 AS is_lead_unlinked,

    ROW_NUMBER() OVER (
        PARTITION BY account_id, is_primary
        ORDER BY created_at ASC
    )                               AS primary_row_num,
    -- primary_row_num > 1 = one account one 

    ROW_NUMBER() OVER (
        PARTITION BY LOWER(TRIM(email))
        ORDER BY created_at ASC
    )                               AS email_row_num
from contacts

)
select * from cleaned