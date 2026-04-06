
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from "revops_analytics"."revops_staging"."stg_subscriptions"
    group by status

)

select *
from all_values
where value_field not in (
    'active','trialing','past_due','cancelled','unpaid','paused'
)


