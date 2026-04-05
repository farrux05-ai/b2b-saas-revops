
  
    
    

    create  table
      "revops_analytics"."marts_marts"."fct_marketing_campaigns__dbt_tmp"
  
    as (
      -- fct_marketing_campaigns.sql

WITH campaigns AS (
    SELECT
        id AS campaign_id,
        name AS campaign_name,
        type AS campaign_type,
        channel AS campaign_channel,
        budget AS campaign_budget,
        spend_actual AS campaign_spend_actual,
        start_date AS campaign_start_date,
        end_date AS campaign_end_date,
        status AS campaign_status,
        created_at AS campaign_created_at,
        is_budget_null,
        is_date_broken,
        spend_pct
    FROM "revops_analytics"."marts_staging"."stg_campaigns"
),

campaign_members AS (
    SELECT
        id AS campaign_member_id,
        lead_id,
        campaign_id,
        first_touch_at,
        last_touch_at,
        responded,
        converted,
        created_at AS campaign_member_created_at,
        is_touch_date_broken
    FROM "revops_analytics"."marts_staging"."stg_campaign_members"
),

leads AS (
    SELECT
        id AS lead_id,
        email AS lead_email,
        first_name AS lead_first_name,
        last_name AS lead_last_name,
        company AS lead_company,
        job_title AS lead_job_title,
        source AS lead_source,
        status AS lead_status,
        lead_score,
        country AS lead_country,
        created_at AS lead_created_at,
        owner_id AS lead_owner_id,
        email_issue,
        source_null,
        score_status_mismatch
    FROM "revops_analytics"."marts_staging"."stg_leads"
)

SELECT
    c.campaign_id,
    c.campaign_name,
    c.campaign_type,
    c.campaign_channel,
    c.campaign_budget,
    c.campaign_spend_actual,
    c.campaign_start_date,
    c.campaign_end_date,
    c.campaign_status,
    c.campaign_created_at,
    c.is_budget_null,
    c.is_date_broken,
    c.spend_pct,
    cm.campaign_member_id,
    cm.first_touch_at,
    cm.last_touch_at,
    cm.responded,
    cm.converted,
    cm.campaign_member_created_at,
    cm.is_touch_date_broken,
    l.lead_id,
    l.lead_email,
    l.lead_first_name,
    l.lead_last_name,
    l.lead_company,
    l.lead_job_title,
    l.lead_source,
    l.lead_status,
    l.lead_score,
    l.lead_country,
    l.lead_created_at,
    l.lead_owner_id,
    l.email_issue,
    l.source_null,
    l.score_status_mismatch
FROM campaigns c
LEFT JOIN campaign_members cm
    ON c.campaign_id = cm.campaign_id
LEFT JOIN leads l
    ON cm.lead_id = l.lead_id
    );
  
  