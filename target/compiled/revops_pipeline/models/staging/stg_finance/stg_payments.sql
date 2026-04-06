with payments as (
    SELECT * FROM postgres_scan(
  'dbname=revops_database user=farrux password=farrux05 host=localhost port=5432',
  'raw',
  'payments'
)
),
cleaned as (
    SELECT
    id,
    invoice_id,
    account_id,
    amount,
    -- Normalize currency to uppercase (e.g. 'usd' → 'USD') for consistent grouping
    TRIM(UPPER(currency))           AS currency,
    TRIM(LOWER(status))             AS status,
    paid_at,

    -- Flag failed payment attempts. Used downstream to calculate payment failure rate per account.
    status = 'failed'               AS is_failed,

    -- Deduplicate payments: same invoice + same amount + same status = duplicate charge.
    -- payment_row_num = 1 is the earliest (canonical) record.
    -- Filter WHERE payment_row_num = 1 in downstream models to avoid double-counting revenue.
    ROW_NUMBER() OVER (
        PARTITION BY invoice_id, amount, status 
        ORDER BY paid_at ASC
    )                               AS payment_row_num
from payments
)
select * from cleaned