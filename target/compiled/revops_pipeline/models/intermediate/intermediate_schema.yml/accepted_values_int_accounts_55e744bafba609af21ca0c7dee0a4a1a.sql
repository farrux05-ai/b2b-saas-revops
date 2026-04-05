
    
    

with all_values as (

    select
        subscription_status as value_field,
        count(*) as n_records

    from "revops_database"."raw_int"."int_accounts"
    group by subscription_status

)

select *
from all_values
where value_field not in (
    'active','past_due','trialing','cancelled'
)


