# B2B SaaS RevOps Pipeline

A production-grade revenue operations data pipeline that unifies customer data from HubSpot, Stripe, Mixpanel, and Intercom into a single source of truth — built with dbt, PostgreSQL, and Streamlit.

---

## The Problem

B2B SaaS companies accumulate data across four separate systems:

| Team | Question | Where they look |
|---|---|---|
| Sales | "Is this account paid?" | Stripe (manually) |
| Customer Success | "Are they using the product?" | Mixpanel (manually) |
| Finance | "What's our MRR this month?" | Excel spreadsheet |
| Leadership | "Where is revenue going?" | Nowhere — no unified view |

This pipeline joins all four sources around a single `account_id` key, building a unified mart layer that any BI tool can query.

---

## Architecture

```
HubSpot  ──┐
Stripe   ──┤                                  ┌── dim_accounts
Mixpanel ──┼──► raw.* ──► stg.* ──► int.* ──┼── fct_revenue
Intercom ──┘                                  └── fct_pipeline
```

### Layer Design

| Layer | Materialization | Purpose |
|---|---|---|
| `raw.*` | Table (append-only) | Immutable raw data as-is from APIs |
| `stg.*` | View | Type casting, cleaning, null flags |
| `int.*` | View | Business logic, joins around `account_id` |
| `marts.*` | Table | Aggregated metrics for BI consumption |

Staging and intermediate as views means zero storage overhead and always-fresh data on mart rebuild. Marts as tables means dashboards never recalculate on every query.

---

## Data Model

All sources join to `stg_accounts` via `account_id`. 1:1 relationships use direct LEFT JOINs; 1:N relationships are aggregated in a CTE before joining to prevent row multiplication.

```
stg_accounts (HubSpot)        ← anchor
    │
    ├── stg_subscriptions      1:1  direct LEFT JOIN
    ├── stg_product_companies  1:1  direct LEFT JOIN
    ├── stg_contacts           1:N  aggregated in CTE first
    ├── stg_opportunities      1:N  aggregated in CTE first
    ├── stg_tickets            1:N  aggregated in CTE first
    └── stg_invoices           1:N  aggregated in CTE first
```

### Key Models

| Model | Row Grain | Description |
|---|---|---|
| `dim_accounts` | One row per account | Health score, MRR, segment, product usage |
| `fct_revenue` | One row per account × month | MRR waterfall: new, expansion, contraction, churn |
| `fct_pipeline` | One row per opportunity | Sales funnel stages, cycle time |

### Account Health Logic

```sql
CASE
  WHEN subscription_status = 'cancelled'   THEN 'churned'
  WHEN subscription_status = 'past_due'    THEN 'at_risk'
  WHEN urgent_open_tickets > 0             THEN 'at_risk'
  WHEN overdue_invoices > 0                THEN 'at_risk'
  WHEN last_active_at < NOW() - INTERVAL '30 days' THEN 'inactive'
  ELSE                                          'healthy'
END
```

---

## Project Structure

```
b2b-saas-revops/
│
├── .github/workflows/
│   └── dbt-ci.yml               # CI: lint + compile on every PR
│
├── models/
│   ├── sources.yml              # Raw table definitions + freshness checks
│   ├── staging/
│   │   ├── stg_sales/           # HubSpot CRM (accounts, contacts, opportunities)
│   │   ├── stg_marketing/       # HubSpot campaigns and leads
│   │   ├── stg_finance/         # Stripe (subscriptions, invoices, payments)
│   │   ├── stg_product/         # Mixpanel (companies, users, events)
│   │   └── stg_support/         # Intercom (tickets, comments)
│   ├── intermediate/
│   │   ├── int_accounts.sql     # Joins all staging sources around account_id
│   │   ├── int_contacts.sql     # Contact dimension with primary contact logic
│   │   └── int_account_health.sql  # Health scoring with product + billing signals
│   └── marts/
│       ├── dim_accounts.sql     # Master account table with all metrics
│       ├── fct_revenue.sql      # Monthly MRR waterfall
│       ├── fct_pipeline.sql     # Sales pipeline and funnel
│       └── fct_marketing_campaigns.sql
│
├── tests/
│   ├── assert_one_row_per_account_in_int.sql
│   ├── assert_revenue_waterfall_balanced.sql
│   ├── assert_health_status_logic_consistent.sql
│   ├── assert_mrr_positive_and_arr_consistent.sql
│   └── assert_no_duplicate_emails_in_staging.sql
│
├── snapshots/
│   ├── snap_dim_accounts.sql    # SCD Type 2: account health history
│   └── snap_fct_pipeline.sql    # SCD Type 2: opportunity stage history
│
├── macros/
│   └── postgres_source.sql      # DuckDB postgres_scan wrapper (reads DSN from env)
│
├── dashboards/
│   ├── app.py                   # Streamlit dashboard
│   └── queries/                 # Reference SQL for each chart
│
├── dbt_project.yml
├── profiles.yml.example         # Copy to ~/.dbt/profiles.yml
├── .env.example                 # Copy to .env and fill credentials
└── requirements.txt
```

---

## Quick Start

### Prerequisites

- Python 3.10+
- PostgreSQL 13+
- dbt-postgres 1.7+

### 1. Clone and install

```bash
git clone https://github.com/farrux05-ai/b2b-saas-revops.git
cd b2b-saas-revops

python -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate

pip install -r requirements.txt
```

### 2. Configure credentials

```bash
# Project environment variables
cp .env.example .env
# Edit .env with your PostgreSQL credentials

# dbt connection profile
cp profiles.yml.example ~/.dbt/profiles.yml
# Edit ~/.dbt/profiles.yml with your PostgreSQL credentials
```

### 3. Run the pipeline

```bash
# Build all models
dbt run

# Run all data quality tests
dbt test

# Build SCD Type 2 snapshots
dbt snapshot

# Explore lineage in browser
dbt docs generate && dbt docs serve
```

### 4. Launch dashboard

```bash
cd dashboards
streamlit run app.py
# Open http://localhost:8501
```

---

## Data Quality

All tests run via `dbt test`. Tests are layered by severity:

| Layer | Severity | Rationale |
|---|---|---|
| `staging` | warn | Raw data may have gaps; don't block ingestion |
| `intermediate` | error | Bad join logic must be caught immediately |
| `marts` | error | BI tools must never see incorrect data |

Custom singular tests include:

- `assert_one_row_per_account_in_int` — prevents fan-out from bad joins
- `assert_revenue_waterfall_balanced` — MRR changes must reconcile month-over-month
- `assert_health_status_logic_consistent` — churned accounts must have cancelled subscriptions
- `assert_mrr_positive_and_arr_consistent` — ARR must equal MRR × 12

Test failures are stored to `raw_test_failures.*` schema for debugging.

---

## Change History (SCD Type 2)

Snapshots track when accounts and opportunities change state over time.

```sql
-- When did an account transition to at_risk?
SELECT
    account_id,
    account_name,
    health_status,
    dbt_valid_from,
    dbt_valid_to       -- NULL means currently in this state
FROM snapshots.snap_dim_accounts
WHERE account_id = 123
ORDER BY dbt_valid_from DESC;
```

Use cases: churn pattern analysis, account tenure by health state, cohort studies before cancellation.

---

## Production Schedule

```bash
# Rebuild pipeline every day at 2 AM
0 2 * * * cd /app/b2b-saas-revops \
  && source .venv/bin/activate \
  && dbt run && dbt snapshot && dbt test
```

---

## Key Metric Definitions

| Metric | Formula |
|---|---|
| MRR | Sum of active subscription `mrr` at point in time |
| ARR | MRR × 12 |
| Expansion MRR | MRR increase for existing active accounts |
| Contraction MRR | MRR decrease for existing active accounts |
| Churned MRR | MRR lost from cancelled accounts |
| Health Status | Rule-based score from billing + support + product signals |

---

## Troubleshooting

**`relation "marts.dim_accounts" does not exist`**
Run `dbt run` first to materialize mart tables.

**`psycopg2.OperationalError: connection failed`**
Verify PostgreSQL is running and credentials in `.env` are correct:
```bash
psql $DATABASE_URL -c "SELECT version()"
```

**`revenue waterfall balanced` test fails**
The tolerance is set to $100 by default. Adjust in `dbt_project.yml`:
```yaml
vars:
  revenue_waterfall_tolerance: 200
```

---

## Tech Stack

**dbt-postgres** · **PostgreSQL** · **DuckDB** · **Streamlit** · **Plotly** · **Python 3.11**

---

*Last updated: March 2026*