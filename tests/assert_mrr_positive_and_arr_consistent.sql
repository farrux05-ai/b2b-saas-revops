-- tests/assert_mrr_positive_and_arr_consistent.sql
--
-- Maqsad: Ikkita biznes qoidani tekshiradi:
--   1. MRR hech qachon manfiy bo'lmasin (billing xatosi signal)
--   2. ARR = MRR × 12 (hisoblash izchil bo'lsin)
--
-- ARR uchun 1 dollar tolerans — float rounding uchun.

SELECT
    account_id,
    mrr,
    arr,
    CASE
        WHEN mrr < 0
            THEN 'mrr_negative'
        WHEN ABS(arr - mrr * 12) > 1
            THEN 'arr_mrr_mismatch'
    END AS failure_reason
FROM {{ ref('dim_accounts') }}
WHERE mrr < 0
   OR ABS(arr - mrr * 12) > 1
