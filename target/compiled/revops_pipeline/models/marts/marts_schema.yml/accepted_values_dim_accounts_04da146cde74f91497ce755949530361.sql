
    
    

with all_values as (

    select
        health_status as value_field,
        count(*) as n_records

    from "revops_database"."raw_marts"."dim_accounts"
    group by health_status

)

select *
from all_values
where value_field not in (
    'healthy','at_risk','inactive','churned'
)


