
      
  
    
    

    create  table
      "revops_analytics"."snapshots"."snap_dim_accounts"
  
    as (
      
    

    select *,
        md5(coalesce(cast(account_id as varchar ), '')
         || '|' || coalesce(cast(updated_at as varchar ), '')
        ) as dbt_scd_id,
        updated_at as dbt_updated_at,
        updated_at as dbt_valid_from,
        
  
  coalesce(nullif(updated_at, updated_at), null)
  as dbt_valid_to
from (
        

  

  SELECT
    account_id,
    account_name,
    product_plan,
    mrr,
    arr,
    subscription_status,
    account_segment,
    total_users,
    active_users,
    events_last_30d,
    last_active_at,
    health_status,
    overdue_invoices,
    urgent_open_tickets,
    total_contacts,
    primary_contact_name,
    primary_lead_source,
    open_opportunities,
    total_won_amount,
    last_won_date,
    updated_at
  FROM "revops_analytics"."marts_marts"."dim_accounts"

    ) sbq



    );
  
  
  