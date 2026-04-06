
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from "revops_analytics"."revops_staging"."stg_tickets"
    group by status

)

select *
from all_values
where value_field not in (
    'open','pending','solved','closed'
)


