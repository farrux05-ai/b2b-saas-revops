with account_health as (
    select * from {{ ref('int_account_health') }}
),

contacts as (
    -- Har account uchun: nechta contact, kim primary
    select
        account_id,
        count(distinct contact_id)              as total_contacts,
        max(case when is_primary then first_name
            || ' ' || last_name end)            as primary_contact_name,
        max(case when is_primary then lead_source
            end)                                as primary_lead_source
    from {{ ref('int_contacts') }}
    group by account_id
),

opportunities as (
    -- Har account uchun: pipeline holati
    select
        account_id,
        count(*) filter (
            where stage not in ('closed_won','closed_lost')
        )                                       as open_opportunities,
        sum(amount) filter (
            where stage = 'closed_won'
        )                                       as total_won_amount,
        max(close_date) filter (
            where stage = 'closed_won'
        )                                       as last_won_date
    from {{ ref('stg_opportunities') }}
    where not is_amount_null
    group by account_id
)

select
    -- Identifikator
    ah.account_id,
    ah.account_name,
    ah.product_plan,
    ah.mrr,
    ah.mrr * 12                                 as arr,
    ah.subscription_status,

    -- Segment: MRR ga qarab
    case
        when ah.mrr >= 2000  then 'enterprise'
        when ah.mrr >= 500   then 'mid_market'
        when ah.mrr > 0      then 'smb'
        else                      'unmonetized'
    end                                         as account_segment,

    -- Product faollik
    ah.total_users,
    ah.active_users,
    ah.events_last_30d,
    ah.last_active_at,

    -- Sog'liq
    ah.health_status,
    ah.overdue_invoices,
    ah.urgent_open_tickets,

    -- Contacts
    c.total_contacts,
    c.primary_contact_name,
    c.primary_lead_source,

    -- Pipeline
    coalesce(o.open_opportunities, 0)           as open_opportunities,
    coalesce(o.total_won_amount, 0)             as total_won_amount,
    o.last_won_date,

    -- Metadata
    current_timestamp                           as updated_at

from account_health ah
left join contacts    c on c.account_id = ah.account_id
left join opportunities o on o.account_id = ah.account_id