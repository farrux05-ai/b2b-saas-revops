{% snapshot snap_dim_accounts %}

  {{
    config(
      target_schema='snapshots',
      unique_key='account_id',
      strategy='check',
      check_cols='all',
    )
  }}

  SELECT
    account_id,
    account_name,
    product_plan,
    mrr,
    arr,
    subscription_status,
    account_segment,
    total_users,
    active_users,
    events_last_30d,
    last_active_at,
    health_status,
    overdue_invoices,
    urgent_open_tickets,
    total_contacts,
    primary_contact_name,
    primary_lead_source,
    open_opportunities,
    total_won_amount,
    last_won_date,
    updated_at
  FROM {{ ref('dim_accounts') }}

{% endsnapshot %}
