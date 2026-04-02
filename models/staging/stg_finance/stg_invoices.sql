with invoices as (
    SELECT * from {{ postgres_source('raw', 'invoices') }}
),
cleaned as (
    SELECT
    id,
    subscription_id,
    account_id,
    amount,
    TRIM(LOWER(status))             AS status,
    due_date,
    paid_at,

    (status = 'open'
     AND due_date < CURRENT_DATE)   AS is_overdue,

    (status = 'paid'
     AND paid_at IS NULL)           AS is_paid_missing_date,

    amount = 0                      AS is_zero_amount
from invoices
)
select * from cleaned