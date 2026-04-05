
    
    

select
    id as unique_field,
    count(*) as n_records

from "revops_database"."raw_staging"."stg_ticket_comments"
where id is not null
group by id
having count(*) > 1


