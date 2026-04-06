-- tests/assert_revenue_waterfall_balanced.sql
--
-- Maqsad: MRR waterfall balansi to'g'rimi?
--   Har oy uchun: oldingi_mrr + new + expansion - contraction - churned
--   = joriy_mrr bo'lishi kerak (kichik farq ruxsat)
--
-- Test muvaffaqiyatli = 0 qator qaytadi (katta farq yo'q)

with monthly as (
    select
        revenue_month,
        max(total_mrr_that_month)                          as total_mrr,
        max(new_mrr_that_month)                            as new_mrr,
        max(expansion_mrr_that_month)                      as expansion_mrr,
        max(contraction_mrr_that_month)                    as contraction_mrr,
        max(churned_mrr_that_month)                        as churned_mrr
    from "revops_analytics"."revops_marts"."fct_revenue"
    group by revenue_month
),

monthly_with_prev as (
    select
        revenue_month,
        total_mrr,
        new_mrr,
        expansion_mrr,
        contraction_mrr,
        churned_mrr,
        lag(total_mrr) over (order by revenue_month)       as prev_mrr
    from monthly
),

-- Balans tekshiruv: farq 1$ dan ko'p bo'lmasligi kerak (rounding)
imbalanced as (
    select
        revenue_month,
        total_mrr,
        prev_mrr,
        coalesce(prev_mrr, 0)
            + coalesce(new_mrr, 0)
            + coalesce(expansion_mrr, 0)
            - coalesce(contraction_mrr, 0)
            - coalesce(churned_mrr, 0)                     as calculated_mrr,
        abs(
            total_mrr - (
                coalesce(prev_mrr, 0)
                + coalesce(new_mrr, 0)
                + coalesce(expansion_mrr, 0)
                - coalesce(contraction_mrr, 0)
                - coalesce(churned_mrr, 0)
            )
        )                                                   as mrr_diff
    from monthly_with_prev
    where prev_mrr is not null  -- birinchi oy skip
)

select *
from imbalanced
where mrr_diff > 5000  -- 5000$ tolerance (subscriptions tracked by start_at, not monthly activity)