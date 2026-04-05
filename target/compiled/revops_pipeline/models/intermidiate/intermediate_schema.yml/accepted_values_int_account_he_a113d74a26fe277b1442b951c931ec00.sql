
    
    

with all_values as (

    select
        health_status as value_field,
        count(*) as n_records

    from "revops_analytics"."marts_int"."int_account_health"
    group by health_status

)

select *
from all_values
where value_field not in (
    'healthy','at_risk','inactive','churned'
)


