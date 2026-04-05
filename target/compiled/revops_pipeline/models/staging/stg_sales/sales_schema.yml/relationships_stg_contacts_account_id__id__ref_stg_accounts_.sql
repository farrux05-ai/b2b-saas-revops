
    
    

with child as (
    select account_id as from_field
    from "revops_database"."raw_staging"."stg_contacts"
    where account_id is not null
),

parent as (
    select id as to_field
    from "revops_database"."raw_staging"."stg_accounts"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


