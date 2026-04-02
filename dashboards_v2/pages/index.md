---
title: RevOps Dashboard
---

<style>
  body {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    color: #111827;
    background: #ffffff;
  }

  h1 {
    font-size: 1.35rem;
    font-weight: 600;
    letter-spacing: -0.01em;
    color: #111827;
    margin-bottom: 0.15rem;
    border: none;
  }

  h2 {
    font-size: 0.7rem;
    font-weight: 600;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: #6b7280;
    margin-top: 2.5rem;
    margin-bottom: 0.75rem;
    padding-bottom: 0.5rem;
    border-bottom: 1px solid #e5e7eb;
  }

  .page-meta {
    font-size: 0.8rem;
    color: #9ca3af;
    margin-bottom: 2rem;
  }
</style>

# RevOps Dashboard
<p class="page-meta">Revenue · Pipeline · Marketing — real-time</p>

## Overview

```sql revenue_summary
select
  coalesce(sum(mrr), 0)                                                              as total_mrr,
  coalesce(sum(arr), 0)                                                              as total_arr,
  count(distinct account_id)                                                         as total_accounts,
  count(distinct case when subscription_status = 'active' then account_id end)      as active_accounts
from dim_accounts
```

<BigValue data={revenue_summary} value=total_mrr       title="Total MRR"        fmt="usd0" />
<BigValue data={revenue_summary} value=total_arr       title="Total ARR"        fmt="usd0" />
<BigValue data={revenue_summary} value=total_accounts  title="Accounts"                   />
<BigValue data={revenue_summary} value=active_accounts title="Active Accounts"            />

## MRR Trend

```sql mrr_trend
select
  revenue_month,
  sum(mrr)                                                        as total_mrr,
  sum(case when mrr_type = 'new'         then mrr else 0 end)    as new_mrr,
  sum(case when mrr_type = 'expansion'   then mrr else 0 end)    as expansion_mrr,
  sum(case when mrr_type = 'contraction' then mrr else 0 end)    as contraction_mrr,
  sum(case when mrr_type = 'churned'     then mrr else 0 end)    as churned_mrr
from fct_revenue
where revenue_month is not null
group by revenue_month
order by revenue_month
```

<LineChart
  data={mrr_trend}
  x=revenue_month
  y=total_mrr
  yFmt="usd0"
/>

## MRR Movement

```sql mrr_movement
select
  revenue_month,
  avg(new_mrr_that_month)          as new_mrr,
  avg(expansion_mrr_that_month)    as expansion_mrr,
  avg(contraction_mrr_that_month)  as contraction_mrr,
  avg(churned_mrr_that_month)      as churned_mrr
from fct_revenue
where revenue_month is not null
group by revenue_month
order by revenue_month
```

<BarChart
  data={mrr_movement}
  x=revenue_month
  y={["new_mrr","expansion_mrr","contraction_mrr","churned_mrr"]}
  yFmt="usd0"
  type=stacked
/>

## Account Segments

```sql segment_breakdown
select
  account_segment,
  count(distinct account_id)   as accounts,
  coalesce(sum(mrr), 0)        as segment_mrr,
  coalesce(avg(mrr), 0)        as avg_mrr
from dim_accounts
where account_segment is not null
group by account_segment
order by segment_mrr desc
```

<BarChart
  data={segment_breakdown}
  x=account_segment
  y=segment_mrr
  yFmt="usd0"
/>

<DataTable
  data={segment_breakdown}
  rows=10
  fmt-segment_mrr=usd0
  fmt-avg_mrr=usd0
/>

## Account Health

```sql health_distribution
select
  health_status,
  count(*)              as account_count,
  coalesce(sum(mrr), 0) as health_mrr
from dim_accounts
where health_status is not null
group by health_status
order by account_count desc
```

<BarChart
  data={health_distribution}
  x=health_status
  y=account_count
/>

<DataTable
  data={health_distribution}
  rows=10
  fmt-health_mrr=usd0
/>

## Sales Pipeline

```sql pipeline_funnel
select
  funnel_stage,
  count(distinct lead_id)               as num_leads,
  coalesce(sum(opportunity_amount), 0)  as total_pipeline_value,
  coalesce(avg(days_lead_to_opp), 0)    as avg_days_lead_to_opp
from fct_pipeline
where funnel_stage is not null
group by funnel_stage
order by
  case funnel_stage
    when 'lead'        then 1
    when 'mql'         then 2
    when 'sql'         then 3
    when 'in_pipeline' then 4
    when 'won'         then 5
    when 'lost'        then 6
    else 7
  end
```

<BarChart
  data={pipeline_funnel}
  x=funnel_stage
  y=num_leads
/>

<DataTable
  data={pipeline_funnel}
  rows=10
  fmt-total_pipeline_value=usd0
/>

## Lead Geography

```sql lead_by_country
select
  lead_country,
  count(distinct lead_id)                                                    as total_leads,
  count(distinct case when funnel_stage = 'won' then lead_id end)           as won_leads
from fct_pipeline
where lead_country is not null
group by lead_country
order by total_leads desc
limit 15
```

<DataTable
  data={lead_by_country}
  rows=15
/>

## Marketing Campaigns

```sql campaign_performance
select
  campaign_name,
  campaign_channel,
  campaign_status,
  coalesce(campaign_budget, 0)        as campaign_budget,
  coalesce(campaign_spend_actual, 0)  as campaign_spend_actual,
  count(distinct lead_id)             as total_leads,
  sum(case when converted = true then 1 else 0 end) as conversions,
  round(
    100.0 * sum(case when converted = true then 1 else 0 end)
    / nullif(count(distinct lead_id), 0),
  1)                                  as conversion_rate_pct
from fct_marketing_campaigns
where campaign_name is not null
group by
  campaign_name,
  campaign_channel,
  campaign_status,
  campaign_budget,
  campaign_spend_actual
order by total_leads desc
limit 15
```

<DataTable
  data={campaign_performance}
  rows=15
  fmt-campaign_budget=usd0
  fmt-campaign_spend_actual=usd0
/>

## Channel Summary

```sql channel_summary
select
  campaign_channel,
  count(distinct campaign_id)             as total_campaigns,
  count(distinct lead_id)                 as total_leads,
  sum(case when converted = true then 1 else 0 end) as total_conversions,
  coalesce(sum(campaign_spend_actual), 0) as total_spend
from fct_marketing_campaigns
where campaign_channel is not null
group by campaign_channel
order by total_leads desc
```

<BarChart
  data={channel_summary}
  x=campaign_channel
  y=total_leads
/>

<DataTable
  data={channel_summary}
  rows=10
  fmt-total_spend=usd0
/>