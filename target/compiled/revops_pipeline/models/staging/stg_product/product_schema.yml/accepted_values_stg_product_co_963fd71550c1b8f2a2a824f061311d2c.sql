
    
    

with all_values as (

    select
        plan as value_field,
        count(*) as n_records

    from "revops_database"."raw_staging"."stg_product_companies"
    group by plan

)

select *
from all_values
where value_field not in (
    'free','starter','growth','enterprise'
)


