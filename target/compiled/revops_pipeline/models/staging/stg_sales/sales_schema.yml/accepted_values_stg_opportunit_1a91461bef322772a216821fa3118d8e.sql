
    
    

with all_values as (

    select
        stage as value_field,
        count(*) as n_records

    from "revops_database"."raw_staging"."stg_opportunities"
    group by stage

)

select *
from all_values
where value_field not in (
    'prospecting','qualification','proposal','closed_won','closed_lost'
)


