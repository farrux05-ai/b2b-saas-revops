-- tests/assert_revenue_waterfall_balanced.sql
{{ config(
    severity = 'error',
    store_failures = true
) }}
--
-- Objective: Ensure the MRR waterfall is balanced
--   For each month: prev_mrr + new + expansion - contraction - churned
--   = current_mrr (with a permitted tolerance)
--
-- Passes if 0 rows returned (no wild imbalances)

with monthly as (
    select
        revenue_month,
        max(total_mrr_that_month)                          as total_mrr,
        max(new_mrr_that_month)                            as new_mrr,
        max(expansion_mrr_that_month)                      as expansion_mrr,
        max(contraction_mrr_that_month)                    as contraction_mrr,
        max(churned_mrr_that_month)                        as churned_mrr
    from {{ ref('fct_revenue') }}
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

-- Balance check: difference should not exceed tolerance
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
    where prev_mrr is not null  -- skip first month
)

select *
from imbalanced
where mrr_diff > 5000  -- 5000$ tolerance (subscriptions tracked by start_at, not monthly activity)
