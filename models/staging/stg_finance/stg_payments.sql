with payments as (
    SELECT * FROM {{ postgres_source('raw', 'payments') }}
),
cleaned as (
    SELECT
    id,
    invoice_id,
    account_id,
    amount,
    TRIM(UPPER(currency))           AS currency,
    TRIM(LOWER(status))             AS status,
    paid_at,

    status = 'failed'               AS is_failed,

    ROW_NUMBER() OVER (
        PARTITION BY invoice_id, amount, status
        ORDER BY paid_at ASC
    )                               AS payment_row_num
    -- payment_row_num > 1 = duplicate payment
from payments
)
select * from cleaned