
  
  create view "revops_analytics"."revops_staging"."stg_contacts__dbt_tmp" as (
    WITH contacts as (
SELECT * FROM postgres_scan(
  'dbname=revops_database user=farrux password=farrux05 host=localhost port=5432',
  'raw',
  'contacts'
)
),
cleaned as (
    SELECT
    id,
    account_id,
    lead_id,
    TRIM(LOWER(email))              AS email,
    TRIM(first_name)                AS first_name,
    TRIM(last_name)                 AS last_name,
    TRIM(job_title)                 AS job_title,
    is_primary,
    created_at,

    -- Flag contacts that were never linked back to a lead record.
    -- Unlinked contacts break lead-to-contact attribution in the pipeline funnel.
    lead_id IS NULL                 AS is_lead_unlinked,

    -- Detect accounts with more than one contact marked as primary.
    -- primary_row_num > 1 means a duplicate primary contact exists for that account.
    ROW_NUMBER() OVER (
        PARTITION BY account_id, is_primary
        ORDER BY created_at ASC
    )                               AS primary_row_num,

    -- Deduplicate contacts by email address.
    -- email_row_num = 1 is the original record; > 1 are duplicates to be excluded downstream.
    ROW_NUMBER() OVER (
        PARTITION BY LOWER(TRIM(email))
        ORDER BY created_at ASC
    )                               AS email_row_num

from contacts
)
select * from cleaned
  );
