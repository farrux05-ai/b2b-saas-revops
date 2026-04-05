
    
    

select
    id as unique_field,
    count(*) as n_records

from "revops_database"."raw_staging"."stg_payments"
where id is not null
group by id
having count(*) > 1


