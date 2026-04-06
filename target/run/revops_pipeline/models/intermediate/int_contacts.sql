
  
  create view "revops_analytics"."revops_int"."int_contacts__dbt_tmp" as (
    with contacts as (
    select * from "revops_analytics"."revops_staging"."stg_contacts"
    where email_row_num = 1
),

leads as (
    select * from "revops_analytics"."revops_staging"."stg_leads"
    where email_row_num = 1
      and email_issue is null
),

first_touch as (
    select distinct on (lead_id)
        lead_id,
        campaign_id,
        first_touch_at
    from "revops_analytics"."revops_staging"."stg_campaign_members"
    where not is_touch_date_broken
    order by lead_id, first_touch_at asc
),

campaigns as (
    select * from "revops_analytics"."revops_staging"."stg_campaigns"
)

select
    c.id                        as contact_id,
    c.account_id,
    c.email,
    c.first_name,
    c.last_name,
    c.job_title,
    c.is_primary,
    c.is_lead_unlinked,

    l.source                    as lead_source,
    l.lead_score,
    l.status                    as lead_status,
    l.created_at                as lead_created_at,

    -- If the campaign record was deleted, fall back to the raw campaign_id from the touch record
    -- to avoid losing attribution data silently
    coalesce(cmp.id, ft.campaign_id)    as first_campaign_id,
    cmp.name                            as first_campaign_name,
    cmp.channel                         as first_campaign_channel

from contacts c
left join leads l        on l.id = c.lead_id
left join first_touch ft on ft.lead_id = l.id
left join campaigns cmp  on cmp.id = ft.campaign_id
  );
