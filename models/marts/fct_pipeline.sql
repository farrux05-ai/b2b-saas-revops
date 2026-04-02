with leads as (
    select * from {{ ref('stg_leads') }}
    where email_row_num = 1
      and email_issue is null
),

contacts as (
    select * from {{ ref('int_contacts') }}
),

opportunities as (
    select * from {{ ref('stg_opportunities') }}
)

select
    l.id                                        as lead_id,
    l.email,
    l.source                                    as lead_source,
    l.lead_score,
    l.status                                    as lead_status,
    l.created_at                                as lead_created_at,

    c.first_campaign_name,
    c.first_campaign_channel,

    -- Qaysi bosqichga yetdi?
    case
        when o.stage = 'closed_won'     then 'won'
        when o.stage = 'closed_lost'    then 'lost'
        when o.id is not null           then 'in_pipeline'
        when l.status = 'sql'           then 'sql'
        when l.status = 'mql'           then 'mql'
        else                                 'lead'
    end                                         as funnel_stage,

    o.amount                                    as opportunity_amount,
    o.stage                                     as opportunity_stage,
    o.close_date,

    -- Qancha vaqt ketdi lead → opportunity
    case
        when o.created_at is not null
        then extract(day from (o.created_at - l.created_at))
        else null
    end                                         as days_lead_to_opp,

    current_timestamp                           as updated_at

from leads l
left join contacts     c on c.contact_id = (
    select id from {{ ref('stg_contacts') }}
    where lead_id = l.id limit 1
)
left join opportunities o on o.lead_id = l.id