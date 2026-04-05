
  
  create view "revops_analytics"."marts_staging"."stg_leads__dbt_tmp" as (
    with leads as
(
  select * from postgres_scan(
  'dbname=revops_database user=farrux password=farrux05 host=localhost port=5432',
  'raw',
  'leads'
)
),
cleaned as(
    select 
    id                  as   id,
    trim(lower(email))  as email,
    trim(first_name)    as first_name,
    trim(last_name)     as last_name,
    trim(company)       as company,
    trim(job_title)   as job_title,
    trim(lower(source))       as source,
    trim(lower(status))    as status,
    coalesce(lead_score, 0)  as lead_score,
    trim(UPPER(country)) as country,
    created_at,
    owner_id,

    --flagship

    case 
        WHEN email is null                  THEN 'null_email'
        WHEN email not like '%@%.%'         THEN 'invalid_form'
        WHEN lower(email) LIKE '%@gmail.com' OR lower(email) LIKE '%@yahoo.com' OR lower(email) LIKE '%@hotmail.com' OR lower(email) LIKE '%@outlook.com' THEN 'personal_email'
    else null 
    end as email_issue,
    source is null as source_null,
    (lead_score = 0 
    and  lower(status) = 'sql') as score_status_mismatch,
    row_number() over(
        partition by lower(email)
        order by created_at desc
    ) as email_row_num
from leads
)
select * from cleaned
  );
