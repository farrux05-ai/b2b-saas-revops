
    
    

with all_values as (

    select
        author_type as value_field,
        count(*) as n_records

    from "revops_analytics"."revops_staging"."stg_ticket_comments"
    group by author_type

)

select *
from all_values
where value_field not in (
    'agent','customer'
)


