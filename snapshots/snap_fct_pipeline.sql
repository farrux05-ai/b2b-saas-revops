{% snapshot snap_fct_pipeline %}

  {{
    config(
      target_schema='snapshots',
      unique_key='lead_id',
      strategy='timestamp',
      updated_at='updated_at',
    )
  }}

  SELECT
    lead_id,
    email,
    lead_source,
    lead_score,
    lead_status,
    lead_created_at,
    first_campaign_name,
    first_campaign_channel,
    funnel_stage,
    opportunity_amount,
    opportunity_stage,
    close_date,
    days_lead_to_opp,
    updated_at
  FROM {{ ref('fct_pipeline') }}

{% endsnapshot %}
