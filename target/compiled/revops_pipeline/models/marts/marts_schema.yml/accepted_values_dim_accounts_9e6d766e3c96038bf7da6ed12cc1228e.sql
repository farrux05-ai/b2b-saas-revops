
    
    

with all_values as (

    select
        account_segment as value_field,
        count(*) as n_records

    from "revops_analytics"."revops_marts"."dim_accounts"
    group by account_segment

)

select *
from all_values
where value_field not in (
    'enterprise','mid_market','smb','unmonetized'
)


