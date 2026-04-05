
      
  
    
    

    create  table
      "revops_analytics"."snapshots"."snap_fct_pipeline"
  
    as (
      
    

    select *,
        md5(coalesce(cast(lead_id as varchar ), '')
         || '|' || coalesce(cast(updated_at as varchar ), '')
        ) as dbt_scd_id,
        updated_at as dbt_updated_at,
        updated_at as dbt_valid_from,
        
  
  coalesce(nullif(updated_at, updated_at), null)
  as dbt_valid_to
from (
        

  

  SELECT
    lead_id,
    email,
    lead_source,
    lead_score,
    lead_status,
    lead_created_at,
    first_campaign_name,
    first_campaign_channel,
    funnel_stage,
    opportunity_amount,
    opportunity_stage,
    close_date,
    days_lead_to_opp,
    updated_at
  FROM "revops_analytics"."marts_marts"."fct_pipeline"

    ) sbq



    );
  
  
  