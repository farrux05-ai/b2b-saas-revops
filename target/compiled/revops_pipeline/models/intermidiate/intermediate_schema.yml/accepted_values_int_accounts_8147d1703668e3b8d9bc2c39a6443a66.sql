
    
    

with all_values as (

    select
        subscription_status as value_field,
        count(*) as n_records

    from "revops_analytics"."marts_int"."int_accounts"
    group by subscription_status

)

select *
from all_values
where value_field not in (
    'active','trialing','past_due','cancelled','unpaid','paused'
)


