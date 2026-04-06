with accounts as (
    select * from {{ ref('int_accounts') }}
),

-- Raw product users (user-level, not aggregated) — reused by both users and events CTEs
-- to avoid scanning stg_product_users twice
raw_users as (
    select
        id,
        account_id,
        status,
        last_seen_at
    from {{ ref('stg_product_users') }}
),

-- Product users — aggregated at account level
users as (
    select
        account_id,
        count(distinct id)                              as total_users,
        count(distinct id) filter (
            where status = 'active'
        )                                               as active_users,
        max(last_seen_at)                               as last_active_at
    from raw_users
    group by account_id
),

-- Product events — last 30 days only, excluding null dates
events as (
    select
        ru.account_id,
        count(pe.id) filter (
            where pe.occurred_at >= now() - interval '{{ var("inactive_days_threshold") }} days'
              and not pe.is_date_null
        )                                               as events_last_30d
    from {{ ref('stg_product_events') }} pe
    join raw_users ru on ru.id = pe.user_id
    group by ru.account_id
)

select
    -- Identity (from int_accounts)
    a.account_id,
    a.account_name,
    a.industry,
    a.country,

    -- Billing signals (from int_accounts — stg_tickets is not re-read here)
    a.mrr,
    a.product_plan,
    a.subscription_status,
    a.is_past_due,
    a.subscription_started_at,
    a.subscription_cancelled_at,

    -- Support signals (from int_accounts — already aggregated)
    a.open_tickets,
    a.urgent_open_tickets,
    a.avg_response_hours,

    -- Finance signals (from int_accounts)
    a.overdue_invoices,

    -- Product signals (computed only here)
    coalesce(u.total_users, 0)                          as total_users,
    coalesce(u.active_users, 0)                         as active_users,
    u.last_active_at,
    coalesce(e.events_last_30d, 0)                      as events_last_30d,

    -- Health score: evaluated in priority order with explicit rules using dbt vars
    case
        when a.subscription_status = 'cancelled'
            then 'churned'
        when a.is_past_due
          or a.urgent_open_tickets > 0
          or a.overdue_invoices > 0
          or a.avg_response_hours > {{ var('at_risk_response_hours') }}
          or a.open_tickets > {{ var('at_risk_open_tickets') }}
          or (u.last_active_at is not null and u.last_active_at < now() - interval '{{ var("at_risk_days_since_active") }} days')
            then 'at_risk'
        when u.last_active_at is not null
         and u.last_active_at < now() - interval '{{ var("inactive_days_threshold") }} days'
         and a.subscription_status in ('active', 'trialing')
            then 'inactive'
        else 'healthy'
    end                                                 as health_status

from accounts a
left join users  u on u.account_id = a.account_id
left join events e on e.account_id = a.account_id
