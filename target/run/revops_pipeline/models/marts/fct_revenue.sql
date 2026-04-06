
  
    
    

    create  table
      "revops_analytics"."revops_marts"."fct_revenue__dbt_tmp"
  
    as (
      with subscriptions as (
    select * from "revops_analytics"."revops_staging"."stg_subscriptions"
    where not is_status_conflict
),

accounts as (
    select account_id, account_name, account_segment
    from "revops_analytics"."revops_marts"."dim_accounts"
),

-- Get previous month MRR and status per account via window functions
with_prev as (
    select
        coalesce(date_trunc('month', started_at), current_date) as revenue_month,
        account_id,
        plan,
        status,
        mrr,

        lag(mrr) over (
            partition by account_id
            order by started_at
        )                                       as prev_mrr,

        lag(status) over (
            partition by account_id
            order by started_at
        )                                       as prev_status

    from subscriptions
),

monthly_revenue as (
    select
        revenue_month,
        account_id,
        plan,
        status,
        mrr,
        prev_mrr,

        -- MRR type classification
        -- prev_mrr IS NULL indicates new revenue
        case
            when status = 'cancelled'                                       then 'churned'
            when status = 'trialing'                                        then 'trial'
            when prev_mrr is null and status in ('active', 'past_due')      then 'new'
            when status in ('active', 'past_due') and mrr > coalesce(prev_mrr, 0)  then 'expansion'
            when status in ('active', 'past_due') and mrr < coalesce(prev_mrr, 0)  then 'contraction'
            when status in ('active', 'past_due') and mrr = coalesce(prev_mrr, 0)  then 'stable'
            else 'unknown'
        end                                                  as mrr_type

    from with_prev
)

select
    mr.revenue_month,
    mr.account_id,
    a.account_name,
    a.account_segment,
    mr.plan,
    mr.status,
    mr.mrr,
    mr.mrr * 12                                              as arr,
    mr.mrr_type,
    mr.prev_mrr,
    mr.mrr - coalesce(mr.prev_mrr, 0)                        as mrr_change,

    -- Aggregated monthly metrics (used for BI waterfall charts)
    sum(mr.mrr) over (
        partition by mr.revenue_month
    )                                                        as total_mrr_that_month,

    sum(case when mr.mrr_type = 'new'
        then mr.mrr else 0 end) over (
        partition by mr.revenue_month
    )                                                        as new_mrr_that_month,

    sum(case when mr.mrr_type = 'expansion'
        then mr.mrr - mr.prev_mrr else 0 end) over (
        partition by mr.revenue_month
    )                                                        as expansion_mrr_that_month,

    sum(case when mr.mrr_type = 'contraction'
        then mr.prev_mrr - mr.mrr else 0 end) over (
        partition by mr.revenue_month
    )                                                        as contraction_mrr_that_month,

    sum(case when mr.mrr_type = 'churned'
        then mr.prev_mrr else 0 end) over (
        partition by mr.revenue_month
    )                                                        as churned_mrr_that_month,

    current_timestamp                                        as updated_at

from monthly_revenue mr
left join accounts a on a.account_id = mr.account_id
where mr.revenue_month is not null
  and mr.mrr_type is not null
    );
  
  