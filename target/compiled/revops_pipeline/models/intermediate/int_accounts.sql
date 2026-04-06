with accounts as (
    select * from "revops_analytics"."revops_staging"."stg_accounts"
),

-- 1:1 — one active subscription per account (exclude conflict rows)
subscriptions as (
    select * from "revops_analytics"."revops_staging"."stg_subscriptions"
    where not coalesce(is_status_conflict, false)
),

-- 1:1 — Mixpanel company-level analytics
product_companies as (
    select * from "revops_analytics"."revops_staging"."stg_product_companies"
),

-- 1:N — aggregate before joining to avoid fan-out
ticket_summary as (
    select
        account_id,
        count(*)                                        as total_tickets,
        count(*) filter (where status = 'open')         as open_tickets,
        count(*) filter (
            where status = 'open' and priority = 'urgent'
        )                                               as urgent_open_tickets,
        avg(hours_to_first_response)                    as avg_response_hours
    from "revops_analytics"."revops_staging"."stg_tickets"
    group by account_id
),

-- 1:N — aggregate before joining to avoid fan-out
invoice_summary as (
    select
        account_id,
        count(*) filter (where is_overdue)              as overdue_invoices,
        count(*) filter (where is_zero_amount)          as zero_amount_invoices
    from "revops_analytics"."revops_staging"."stg_invoices"
    group by account_id
)

select
    -- Identity
    a.id                                                as account_id,
    a.name                                              as account_name,
    a.domain,
    a.industry,
    a.country,
    a.employee_count,
    a.owner_id,
    a.created_at                                        as account_created_at,

    -- DQ flags
    a.is_industry_null,
    a.is_owner_null,

    -- Billing (1:1)
    coalesce(s.mrr, 0)                                  as mrr,
    s.plan                                              as product_plan,
    s.status                                            as subscription_status,
    s.is_past_due,
    s.is_mrr_zero,
    s.trial_start,
    s.trial_end,
    s.started_at                                        as subscription_started_at,
    s.cancelled_at                                      as subscription_cancelled_at,

    -- Product (1:1)
    coalesce(p.seat_count, 0)                              as seat_count,

    -- Support (aggregated — safe join)
    coalesce(t.total_tickets, 0)                        as total_tickets,
    coalesce(t.open_tickets, 0)                         as open_tickets,
    coalesce(t.urgent_open_tickets, 0)                  as urgent_open_tickets,
    t.avg_response_hours,

    -- Finance (aggregated — safe join)
    coalesce(i.overdue_invoices, 0)                     as overdue_invoices,
    coalesce(i.zero_amount_invoices, 0)                 as zero_amount_invoices

from accounts a
left join subscriptions     s on s.account_id = a.id
left join product_companies p on p.account_id = a.id
left join ticket_summary    t on t.account_id = a.id
left join invoice_summary   i on i.account_id = a.id