with ticket_comments as (
    select * from postgres_scan(
  'dbname=revops_database user=farrux password=farrux05 host=localhost port=5432',
  'raw',
  'ticket_comments'
)
),
cleaned as(
    SELECT
    id,
    ticket_id,
    TRIM(LOWER(author_type))        AS author_type,
    body,
    created_at,

    author_type IS NULL             AS is_author_null,
    body IS NULL                    AS is_body_null
from ticket_comments
)
select * from cleaned