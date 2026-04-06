
    
    

with all_values as (

    select
        type as value_field,
        count(*) as n_records

    from "revops_analytics"."revops_staging"."stg_activities"
    group by type

)

select *
from all_values
where value_field not in (
    'call','email','meeting','demo','note'
)


