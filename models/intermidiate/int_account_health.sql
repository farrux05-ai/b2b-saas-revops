with accounts as (
    select * from {{ ref('int_accounts') }}
),

users as (
    select
        account_id,
        count(distinct id)                          as total_users,
        count(distinct id) filter (
            where status = 'active'
        )                                           as active_users,
        max(last_seen_at)                           as last_active_at
    from {{ ref('stg_product_users') }}
    group by account_id
),

events as (
    select
        pu.account_id,
        count(pe.id) filter (
            where pe.occurred_at >= now() - interval '30 days'
              and not pe.is_date_null
        )                                           as events_last_30d
    from {{ ref('stg_product_events') }} pe
    left join {{ ref('stg_product_users') }} pu on pu.id = pe.user_id
    group by pu.account_id
),

invoices as (
    select
        account_id,
        count(*) filter (where is_overdue)          as overdue_invoices
    from {{ ref('stg_invoices') }}
    group by account_id
),

tickets as (
    select
        account_id,
        count(*) filter (
            where status = 'open' and priority = 'urgent'
        )                                           as urgent_open_tickets
    from {{ ref('stg_tickets') }}
    group by account_id
)

select
    a.account_id,
    a.account_name,
    a.product_plan,
    a.mrr,
    a.subscription_status,
    a.open_tickets,

    coalesce(u.total_users, 0)      as total_users,
    coalesce(u.active_users, 0)     as active_users,
    u.last_active_at,
    coalesce(e.events_last_30d, 0)  as events_last_30d,
    coalesce(i.overdue_invoices, 0) as overdue_invoices,
    coalesce(t.urgent_open_tickets, 0) as urgent_open_tickets,

    case
        when a.subscription_status = 'cancelled'        then 'churned'
        when a.subscription_status = 'past_due'         then 'at_risk'
        when t.urgent_open_tickets > 0                  then 'at_risk'
        when i.overdue_invoices > 0                     then 'at_risk'
        when u.last_active_at < now() - interval '30 days' then 'inactive'
        else                                                 'healthy'
    end                             as health_status

from accounts a
left join users u    on u.account_id = a.account_id
left join events e   on e.account_id = a.account_id
left join invoices i on i.account_id = a.account_id
left join tickets t  on t.account_id = a.account_id
