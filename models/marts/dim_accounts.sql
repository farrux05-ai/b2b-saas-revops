with account_health as (
    select * from {{ ref('int_account_health') }}
),

-- 1:N → avval aggregate
contacts as (
    select
        account_id,
        count(distinct contact_id)                      as total_contacts,
        max(first_name || ' ' || last_name)
            filter (where is_primary)                   as primary_contact_name,
        max(lead_source)
            filter (where is_primary)                   as primary_lead_source
    from {{ ref('int_contacts') }}
    group by account_id
),

-- 1:N → avval aggregate
opportunities as (
    select
        account_id,
        count(*) filter (
            where stage not in ('closed_won', 'closed_lost')
        )                                               as open_opportunities,
        coalesce(sum(amount) filter (
            where stage = 'closed_won'
        ), 0)                                           as total_won_amount,
        max(close_date) filter (
            where stage = 'closed_won'
        )                                               as last_won_date
    from {{ ref('stg_opportunities') }}
    where not is_amount_null
    group by account_id
)

select
    -- Identity
    ah.account_id,
    ah.account_name,
    ah.industry,
    ah.country,

    -- Billing
    ah.mrr,
    ah.mrr * 12                                         as arr,
    ah.product_plan,
    ah.subscription_status,
    ah.is_past_due,
    ah.subscription_started_at,
    ah.subscription_cancelled_at,

    -- Segment: coalesce(mrr,0) — NULL mrr → 'unmonetized', hech qachon NULL
    case
        when coalesce(ah.mrr, 0) >= 2000   then 'enterprise'
        when coalesce(ah.mrr, 0) >= 500    then 'mid_market'
        when coalesce(ah.mrr, 0) >  0      then 'smb'
        else                                    'unmonetized'
    end                                                 as account_segment,

    -- Product signals
    ah.total_users,
    ah.active_users,
    ah.events_last_30d,
    ah.last_active_at,

    -- Health
    ah.health_status,
    ah.urgent_open_tickets,
    ah.open_tickets,
    ah.avg_response_hours,
    ah.overdue_invoices,

    -- Contacts
    coalesce(c.total_contacts, 0)                       as total_contacts,
    c.primary_contact_name,
    c.primary_lead_source,

    -- Pipeline
    coalesce(o.open_opportunities, 0)                   as open_opportunities,
    coalesce(o.total_won_amount, 0)                     as total_won_amount,
    o.last_won_date,

    -- Metadata
    current_timestamp                                   as updated_at

from account_health ah
left join contacts    c on c.account_id = ah.account_id
left join opportunities o on o.account_id = ah.account_id