
    
    

with all_values as (

    select
        funnel_stage as value_field,
        count(*) as n_records

    from "revops_database"."raw_marts"."fct_pipeline"
    group by funnel_stage

)

select *
from all_values
where value_field not in (
    'lead','mql','sql','in_pipeline','won','lost'
)


