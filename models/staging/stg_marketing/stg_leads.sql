with leads as
(
  select * from {{ postgres_source('raw', 'leads') }}
),
cleaned as(
    select 
    id                  as   id,
    trim(lower(email))  as email,
    trim(first_name)    as first_name,
    trim(last_name)     as last_name,
    trim(company)       as company,
    trim(job_title)     as job_title,
    trim(lower(source)) as source,
    trim(lower(status)) as status,
    -- Replace NULL lead scores with 0 so downstream aggregations never fail on NULLs
    coalesce(lead_score, 0) as lead_score,
    trim(UPPER(country)) as country,
    created_at,
    owner_id,

    -- Email quality classification:
    -- 'null_email'     → no email provided at all
    -- 'invalid_format' → email does not match basic pattern (@domain.tld)
    -- 'personal_domain'→ email is from a consumer provider (gmail, yahoo, etc.)
    -- NULL             → email looks valid and professional
    case 
        when email is null                   then 'null_email'
        when email not like '%@%.%'          then 'invalid_format'
        when lower(email) like '%@gmail.com'
          or lower(email) like '%@yahoo.com'
          or lower(email) like '%@hotmail.com'
          or lower(email) like '%@outlook.com' then 'personal_domain'
        else null 
    end as email_issue,

    -- Flag leads where the traffic source was not captured (data hygiene)
    source is null as source_null,

    -- Flag impossible state: a lead scored 0 but already marked as SQL
    -- This usually means the scoring model ran before the lead was fully enriched
    (lead_score = 0 and lower(status) = 'sql') as score_status_mismatch,

    -- Deduplicate leads by email. Row 1 = most recent record (use WHERE email_row_num = 1 downstream)
    row_number() over(
        partition by lower(email)
        order by created_at desc
    ) as email_row_num

from leads
)
select * from cleaned