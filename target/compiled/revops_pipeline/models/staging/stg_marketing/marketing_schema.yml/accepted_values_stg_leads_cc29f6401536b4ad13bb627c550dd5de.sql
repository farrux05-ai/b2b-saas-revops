
    
    

with all_values as (

    select
        email_issue as value_field,
        count(*) as n_records

    from "revops_analytics"."revops_staging"."stg_leads"
    group by email_issue

)

select *
from all_values
where value_field not in (
    'null_email','invalid_format','personal_domain'
)


