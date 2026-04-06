with accounts as (
    select * from "revops_analytics"."revops_int"."int_accounts"
),

-- Product users — account darajasida aggregate
users as (
    select
        account_id,
        count(distinct id)                              as total_users,
        count(distinct id) filter (
            where status = 'active'
        )                                               as active_users,
        max(last_seen_at)                               as last_active_at
    from "revops_analytics"."revops_staging"."stg_product_users"
    group by account_id
),

-- Product events — faqat so'nggi 30 kun, NULL sanalarsiz
events as (
    select
        pu.account_id,
        count(pe.id) filter (
            where pe.occurred_at >= now() - interval '30 days'
              and not pe.is_date_null
        )                                               as events_last_30d
    from "revops_analytics"."revops_staging"."stg_product_events" pe
    join "revops_analytics"."revops_staging"."stg_product_users"  pu on pu.id = pe.user_id
    group by pu.account_id
)

select
    -- Identity (int_accounts dan)
    a.account_id,
    a.account_name,
    a.industry,
    a.country,

    -- Billing signals (int_accounts dan — stg_tickets ikkinchi marta o'qilmaydi)
    a.mrr,
    a.product_plan,
    a.subscription_status,
    a.is_past_due,
    a.subscription_started_at,
    a.subscription_cancelled_at,

    -- Support signals (int_accounts dan — already aggregated)
    a.open_tickets,
    a.urgent_open_tickets,
    a.avg_response_hours,

    -- Finance signals (int_accounts dan)
    a.overdue_invoices,

    -- Product signals (yangi, faqat shu yerda)
    coalesce(u.total_users, 0)                          as total_users,
    coalesce(u.active_users, 0)                         as active_users,
    u.last_active_at,
    coalesce(e.events_last_30d, 0)                      as events_last_30d,

    -- Health score: priority tartibida, aniq qoidalar
    case
        when a.subscription_status = 'cancelled'
            then 'churned'
        when a.is_past_due
          or a.urgent_open_tickets > 0
          or a.overdue_invoices > 0
            then 'at_risk'
        when u.last_active_at is not null
         and u.last_active_at < now() - interval '30 days'
         and a.subscription_status = 'active'
            then 'inactive'
        else 'healthy'
    end                                                 as health_status

from accounts a
left join users  u on u.account_id = a.account_id
left join events e on e.account_id = a.account_id