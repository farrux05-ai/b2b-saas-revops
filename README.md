# B2B SaaS RevOps Pipeline

[![dbt Cloud](https://img.shields.io/badge/dbt-Core-FF6849?style=flat&logo=dbt)](https://www.getdbt.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-13+-336791?style=flat&logo=postgresql)](https://www.postgresql.org/)
[![Evidence](https://img.shields.io/badge/Evidence-Analytics-4A90E2?style=flat)](https://www.evidence.dev/)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=flat&logo=python)](https://www.python.org/)

A production-grade revenue operations data pipeline that unifies customer data from HubSpot, Stripe, Mixpanel, and Intercom into a single source of truth — built with **dbt**, **PostgreSQL**, **duckdb**, **Evidence**.

Status: Production Ready | Data freshness: Daily | Test Coverage: 167 tests

---

## The Problem

Revenue teams at B2B SaaS companies face a critical challenge:

**Sales asks:** "Is this $50K enterprise account paid up?"  
→ *Must manually check Stripe*

**Customer Success asks:** "Which accounts are at-risk of churning?"  
→ *No visibility into product usage + payment behavior together*

**Finance asks:** "What's our MRR growth this quarter?"  
→ *4 hours of manual Excel work, prone to errors*

**Leadership asks:** "Where should we focus expansion efforts?"  
→ *Data scattered across 4 tools, no unified view*

**The root cause:** Customer data lives in silos. Each team sees one dimension, nobody sees the full picture.

---

##  The Solution

This pipeline creates a **single source of truth** by:

1. **Unifying 4 data sources** around `account_id` as the central entity
2. **Automating transformations** with dbt for consistent business logic  
3. **Tracking history** with SCD Type 2 snapshots to understand lifecycle changes
4. **Delivering insights** via Evidence.dev interactive reports

### Business Impact

- **MRR calculation:** 4 hours → 5 minutes (automated)
- **Churn visibility:** Reactive → Proactive (identified $45K at-risk revenue)
- **Decision speed:** Days → Real-time (live health scoring)
- **Data trust:** Fragmented → Single source of truth

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
├── dashboards_v2/               # Evidence Analytics (modern replacement)
│   ├── pages/
│   │   └── index.md             # Revenue, Pipeline, Marketing dashboard
│   ├── sources/
│   │   └── queries/             # dbt source definitions
│   ├── evidence.config.yaml     # Evidence configuration
│   └── package.json
│
├── screenshots/                 # Dashboard evidence
│   ├── mrr_trend.jpg           # Monthly MRR trend
│   ├── mrr_movement.jpg        # MRR waterfall by type
│   ├── channel_summary.jpg     # Marketing channel breakdown
│   └── account_segment.jpg     # Account segmentation by MRR
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

---

## Dashboard Visualization

### Evidence Analytics Dashboard (Recommended)

Modern, interactive Revenue Operations dashboard powered by Evidence.

Features:
- Real-time KPI metrics (MRR, ARR, account count)
- MRR trend analysis with new/expansion/contraction/churn breakdown
- Account segmentation by revenue and health
- Sales pipeline funnel (Lead to MQL to SQL to Won)
- Geographic lead distribution
- Marketing campaign performance and ROI by channel

Access:
```bash
cd dashboards_v2
npm install
npm run dev
# Open http://localhost:3000
```

**Dashboard Queries (from `dashboards_v2/pages/index.md`):**

| Section | Metric | Query |
|---------|--------|-------|
| Overview | Total MRR | `SUM(mrr)` from `dim_accounts` |
| | Total ARR | `MRR × 12` |
| | Active Accounts | `COUNT(subscription_status = 'active')` |
| MRR Trend | Monthly progression | Group by `revenue_month` from `fct_revenue` |
| | Revenue types | New, Expansion, Contraction, Churned |
| Account Health | Status distribution | Group by `health_status` from `dim_accounts` |
| Sales Pipeline | Funnel stages | Lead to MQL to SQL to In Pipeline to Won to Lost |
| Marketing | Channel ROI | `campaign_spend_actual / total_conversions` |

### Legacy Streamlit Dashboard

Alternative Streamlit-based dashboard (for reference):

```bash
cd dashboards
streamlit run app.py
# Open http://localhost:8501
```

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

---

## Dashboard Setup (Evidence)

Evidence is a modern BI tool that connects directly to your data warehouse and renders interactive dashboards from SQL and Markdown.

### Why Evidence?

- No separate BI tool needed (Tableau, Looker)
- Dashboards live in version control (git)
- Write queries in SQL, visualizations auto-generated
- Deploy to Vercel or run locally
- Real-time data (queries hit data warehouse on load)

### Setup Steps

**1. Install dependencies**
```bash
cd dashboards_v2
npm install
```

**2. Connect to your database**

Evidence reads from `sources/` config. Already configured for your PostgreSQL:
```yaml
# sources/postgres.yml (auto-created)
type: postgres
host: localhost
port: 5432
database: revops
user: <your_user>
password: <your_password>
```

**3. Run locally**
```bash
npm run dev
```
Open `http://localhost:3000` to see dashboard with live data.

**4. Deploy to Vercel** (optional)
```bash
npm run build
# Push to GitHub, Vercel auto-deploys on push
```

### Dashboard Contents (Evidence)

Located in `dashboards_v2/pages/index.md`:

**Section 1: Revenue Overview**
- Total MRR, ARR, Account Count, Active Accounts
- Metric: MRR from active subscriptions

**Section 2: MRR Trend Chart**
- Line chart of total MRR by month
- Shows: Revenue growth trajectory

**Section 3: MRR Movement (Stacked Bar)**
- New, Expansion, Contraction, Churned breakdown
- Shows: Revenue composition month-over-month

**Section 4: Account Segments**
- Accounts by segment with average MRR
- Shows: Which segments drive revenue

**Section 5: Account Health Distribution**
- Count of Healthy, At-Risk, Churned accounts
- Shows: Health score composition

**Section 6: Sales Pipeline Funnel**
- Lead to MQL to SQL to In Pipeline to Won to Lost
- Shows: Conversion rates at each stage

**Section 7: Lead Geography**
- Top 15 countries by lead volume
- Shows: Geographic distribution

**Section 8: Marketing Campaigns**
- Campaign name, channel, budget, spend, conversions, ROI
- Shows: Which campaigns drive value

**Section 9: Channel Summary**
- Total leads, conversions, spend by channel
- Shows: Channel efficiency

---

## Troubleshooting

### dbt and Data Layer

**Relation "marts.dim_accounts" does not exist**
Run `dbt run` first to materialize mart tables.

**psycopg2.OperationalError: connection failed**
Verify PostgreSQL is running and credentials in `.env` are correct:
```bash
psql $DATABASE_URL -c "SELECT version()"
```

**Revenue waterfall balanced test fails**
The tolerance is set to $100 by default. Adjust in `dbt_project.yml`:
```yaml
vars:
  revenue_waterfall_tolerance: 200
```

### Evidence Dashboard

**Error: No data source configured**
Ensure `dashboards_v2/sources/` folder exists with `postgres.yml` or `evidence.config.yaml` is properly set:
```yaml
sources:
  - name: postgres
    type: postgres
    host: localhost
    port: 5432
    database: revops_db
```

**npm ERR! code ENOENT, no such file or directory**
Install dependencies first:
```bash
cd dashboards_v2
npm install
```

**Evidence dev server stuck or not loading**
Clear cache and restart:
```bash
cd dashboards_v2
rm -rf .evidence
npm run dev
```

**Dashboard shows "Loading..." but never loads**
Check if PostgreSQL connection works:
```bash
psql -h localhost -U <user> -d revops_db -c "SELECT COUNT(*) FROM dim_accounts;"
```
If query hangs, your dbt models haven't run yet. Run `dbt run` in parent directory.

---

## Tech Stack

**dbt-postgres** · **PostgreSQL** · **DuckDB** · **Evidence** · **Streamlit** · **Plotly** · **Python 3.10+** · **Node.js 18+**

---

## Dashboard Screenshots

### MRR Trend Analysis
Real-time monthly recurring revenue trend with clear growth trajectory.

![MRR Trend](./screenshots/mrr_trend.jpg)

### MRR Movement Waterfall
Revenue composition breakdown: New, Expansion, Contraction, and Churned MRR by month.

![MRR Movement](./screenshots/mrr_movement.jpg)

### Account Segmentation
Revenue distribution across customer segments with segment-level metrics.

![Account Segment](./screenshots/account_segment.jpg)

### Marketing Channel Performance
Lead generation and conversion rates by channel source.

![Channel Summary](./screenshots/channel_summary.jpg)

---

## Key Features

Production-ready revenue operations data pipeline with integrated analytics:

- Unified Data Model: One account_id across all sources
- Real-time Dashboards: Evidence and Streamlit options
- Data Quality: 167 automated tests covering all layers
- Change History: SCD Type 2 snapshots for churn analysis
- Production Ready: Daily refresh schedule with error monitoring
- Extensible: Add new sources in 3 steps (sources.yml to stg_ to int_)

---

*Last updated: April 2026*