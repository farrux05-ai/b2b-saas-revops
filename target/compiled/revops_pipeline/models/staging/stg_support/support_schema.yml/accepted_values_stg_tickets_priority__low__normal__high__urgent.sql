
    
    

with all_values as (

    select
        priority as value_field,
        count(*) as n_records

    from "revops_database"."raw_staging"."stg_tickets"
    group by priority

)

select *
from all_values
where value_field not in (
    'low','normal','high','urgent'
)


