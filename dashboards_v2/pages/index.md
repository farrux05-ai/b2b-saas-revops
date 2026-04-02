# RevOps Analytics Dashboard
```sql revenue_summary
select
  sum(mrr) as total_mrr,
  sum(arr) as total_arr,
  count(distinct account_id) as total_accounts
from dim_accounts
```

<BigValue data={revenue_summary} value=total_mrr title="Total MRR" fmt="usd" />
<BigValue data={revenue_summary} value=total_arr title="Total ARR" fmt="usd" />
<BigValue data={revenue_summary} value=total_accounts title="Total Accounts" />

## MRR Trend
```sql mrr_trend
select
  revenue_month,
  sum(mrr) as total_mrr
from fct_revenue
where revenue_month is not null
group by revenue_month
order by revenue_month
```

<LineChart data={mrr_trend} x=revenue_month y=total_mrr title="Monthly Recurring Revenue" />

## Account Health
```sql health_distribution
select
  health_status,
  count(*) as account_count
from dim_accounts
where health_status is not null
group by health_status
order by account_count desc
```

<BarChart data={health_distribution} x=health_status y=account_count title="Accounts by Health Status" />

## Sales Pipeline
```sql pipeline_funnel
select
  funnel_stage,
  count(*) as num_leads,
  sum(opportunity_amount) as total_pipeline
from fct_pipeline
group by funnel_stage
order by funnel_stage
```

<DataTable data={pipeline_funnel} />
