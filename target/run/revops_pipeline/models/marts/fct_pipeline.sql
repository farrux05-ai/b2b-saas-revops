
  
    
    

    create  table
      "revops_analytics"."marts_marts"."fct_pipeline__dbt_tmp"
  
    as (
      -- Grain: bir qator = bir lead.
-- Lead → MQL → SQL → Opportunity → Won/Lost funnel.

with leads as (
    select * from "revops_analytics"."marts_staging"."stg_leads"
    -- faqat eng yangi email, valid email
    where email_row_num = 1
      and email_issue is null
),

opportunities as (
    select * from "revops_analytics"."marts_staging"."stg_opportunities"
),

-- Har lead uchun bitta contact (eng eski created_at)
contact_per_lead as (
    select distinct on (lead_id)
        lead_id,
        account_id
    from "revops_analytics"."marts_staging"."stg_contacts"
    where lead_id is not null
    order by lead_id, created_at asc
),

-- FIX: Subquery o'rniga Primary Contact-larni oldindan ajratib olamiz
primary_contacts as (
    select *
    from "revops_analytics"."marts_int"."int_contacts"
    where is_primary = true
),

funnel as (
    select
        l.id                                            as lead_id,
        l.email,
        l.source                                        as lead_source,
        l.lead_score,
        l.status                                        as lead_status,
        l.created_at::DATE                              as lead_created_at,
        l.country                                       as lead_country,

        -- Campaign attribution
        c.first_campaign_name,
        c.first_campaign_channel,

        -- Account link
        cpl.account_id,

        -- Opportunity
        o.id                                            as opportunity_id,
        o.stage                                         as opportunity_stage,
        o.amount                                        as opportunity_amount,
        o.close_date::DATE                              as close_date,
        o.created_at::DATE                              as opportunity_created_at,

        -- Funnel stage: priority tartibida
        case
            when o.stage = 'closed_won'     then 'won'
            when o.stage = 'closed_lost'    then 'lost'
            when o.id is not null           then 'in_pipeline'
            when l.status = 'sql'           then 'sql'
            when l.status = 'mql'           then 'mql'
            else                                 'lead'
        end                                             as funnel_stage,

        -- FIX: DuckDB uchun sana ayirmasi (extract shart emas)
        case
            when o.created_at is not null
            then (o.created_at::DATE - l.created_at::DATE)
        end                                             as days_lead_to_opp,

        case
            when o.close_date is not null and o.created_at is not null
            then (o.close_date::DATE - o.created_at::DATE)
        end                                             as days_opp_to_close

    from leads l
    left join contact_per_lead cpl on cpl.lead_id = l.id
    -- FIX: Correlated subquery JOIN ga almashtirildi
    left join primary_contacts c   on c.account_id = cpl.account_id
    left join opportunities o      on o.lead_id = l.id
)

select
    lead_id,
    email,
    lead_source,
    lead_score,
    lead_status,
    lead_created_at,
    lead_country,
    first_campaign_name,
    first_campaign_channel,
    account_id,
    opportunity_id,
    opportunity_stage,
    opportunity_amount,
    close_date,
    funnel_stage,
    days_lead_to_opp,
    days_opp_to_close,
    current_timestamp                                   as updated_at

from funnel
    );
  
  