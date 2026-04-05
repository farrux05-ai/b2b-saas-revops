
    
    

with all_values as (

    select
        status as value_field,
        count(*) as n_records

    from "revops_database"."raw_staging"."stg_leads"
    group by status

)

select *
from all_values
where value_field not in (
    'new','mql','sql','disqualified'
)


