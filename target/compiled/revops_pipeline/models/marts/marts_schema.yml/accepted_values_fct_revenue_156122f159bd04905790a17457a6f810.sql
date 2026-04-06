
    
    

with all_values as (

    select
        mrr_type as value_field,
        count(*) as n_records

    from "revops_analytics"."revops_marts"."fct_revenue"
    group by mrr_type

)

select *
from all_values
where value_field not in (
    'new','expansion','contraction','stable','churned','trial'
)


