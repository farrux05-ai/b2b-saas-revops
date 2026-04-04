# B2B SaaS RevOps Pipeline

[![dbt Cloud](https://img.shields.io/badge/dbt-Core-FF6849?style=flat&logo=dbt)](https://www.getdbt.com/)
[![DuckDB](https://img.shields.io/badge/DuckDB-1.0+-FF6849?style=flat)](https://duckdb.org/)
[![Evidence](https://img.shields.io/badge/Evidence-Analytics-4A90E2?style=flat)](https://www.evidence.dev/)
[![Python](https://img.shields.io/badge/Python-3.12+-3776AB?style=flat&logo=python)](https://www.python.org/)

A production-grade revenue operations data pipeline that unifies customer data from HubSpot, Stripe, Mixpanel, and Intercom into a single source of truth — built with **dbt**, **DuckDB**, and **Evidence**.

Status: Production Ready | Data freshness: Daily | Test Coverage: 158 tests | 22 models | 2 snapshots

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
├── dashboards_v2/               # Evidence Analytics (interactive BI dashboards)
│   ├── pages/
│   │   ├── index.md             # Revenue, Pipeline, and Account Health dashboard
│   │   └── queries/             # SQL queries for each visualization
│   ├── sources/
│   │   └── revops/              # DuckDB connection configuration
│   ├── evidence.config.yaml     # Evidence.dev configuration
│   ├── package.json
│   └── README.md
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

- Python 3.12+
- dbt 1.7+
- PostgreSQL 13+ (source - optional, can use any supported source)

### 1. Clone and install

```bash
git clone https://github.com/farrux05-ai/b2b-saas-revops.git
cd b2b-saas-revops/revops_pipeline/revops_project

# Create and activate Python environment
python -m venv dbt-venv
source dbt-venv/bin/activate          # Windows: dbt-venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure credentials

```bash
# Set environment variables for your data source
export DBT_POSTGRES_USER=your_user
export DBT_POSTGRES_PASSWORD=your_password
export DBT_POSTGRES_HOST=localhost
export DBT_POSTGRES_PORT=5432
```

### 3. Run the pipeline

```bash
# Test connection
dbt debug

# Build all models
dbt run

# Run all data quality tests (158 tests)
dbt test

# Build SCD Type 2 snapshots
dbt snapshot

# Explore data lineage in browser
dbt docs generate && dbt docs serve
# Open http://localhost:8080
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
| | Total ARR | `SUM(arr)` from `dim_accounts` |
| | Active Accounts | `COUNT(*)` where `subscription_status = 'active'` |
| MRR Trend | Monthly progression | Group by `revenue_month` from `fct_revenue` |
| | Revenue types | Breakdown: New, Expansion, Contraction, Churned |
| Account Health | Status distribution | Count by `health_status` from `dim_accounts` |
| Account Segment | Revenue segment performance | Distribution by `account_segment` (SMB, Mid-Market, Enterprise) |
| Sales Pipeline | Deal progression | Count of opportunities by `funnel_stage` |

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

### dbt Setup Issues

**"dbt: command not found"**
Make sure your virtual environment is activated:
```bash
source dbt-venv/bin/activate
```

**"Relation "marts.dim_accounts" does not exist"**
Run `dbt run` to build the models first.

**"Environment variable DBT_POSTGRES_PASSWORD not set"**
Set your PostgreSQL credentials:
```bash
export DBT_POSTGRES_USER=your_user
export DBT_POSTGRES_PASSWORD=your_password
```

### Evidence Dashboard Issues

**"Error: No data source configured"**
Verify `dashboards_v2/sources/revops/connection.yaml` points to correct DuckDB path:
```yaml
name: revops
type: duckdb
options:
  filename: ../duckdb/revops_analytics.duckdb
```

**"npm ERR! code ENOENT"**
Install dependencies first:
```bash
cd dashboards_v2
npm install
```

**"Error loading data"**
Make sure you've run the dbt pipeline first:
```bash
dbt run && dbt snapshot
```

---

## Tech Stack

- **Orchestration:** dbt 1.7+
- **Data Warehouse:** DuckDB (local) / PostgreSQL (source)
- **Analytics:** Evidence.dev
- **Language:** SQL, Python 3.12
- **Node.js:** 18+ (for Evidence dashboard)

---

## Documentation

- [Case Study](./docs/CASE_STUDY.md) — Business impact and implementation story
- [Technical Deep-Dive](./docs/TECHNICAL.md) — Architecture decisions and advanced topics

---

## Dashboard Screenshots

### 1. MRR Trend Analysis
Monthly recurring revenue trend with clear growth trajectory and visualization of revenue changes over time.

![MRR Trend](./screenshots/mrr_trend.jpg)

### 2. MRR Movement Waterfall
Revenue composition breakdown showing New, Expansion, Contraction, and Churned MRR by month. Key metric for understanding revenue dynamics.

![MRR Movement](./screenshots/mrr_movement.jpg)

### 3. Account Segmentation  
Revenue distribution and metrics across customer segments (SMB, Mid-Market, Enterprise) with average MRR per segment.

![Account Segment](./screenshots/account_segment.jpg)

### 4. Marketing Channel Performance
Lead generation and conversion rates by channel source. ROI analysis for each marketing channel.

![Channel Summary](./screenshots/channel_summary.jpg)

---

## Key Features

Production-ready revenue operations data pipeline with integrated analytics:

- **Unified Data Model:** One `account_id` across all sources (HubSpot, Stripe, Mixpanel, Intercom)
- **Interactive Dashboards:** Evidence.dev dashboards for revenue, health, and pipeline analytics
- **Comprehensive Testing:** 158 automated data quality tests across all layers
- **Change Tracking:** SCD Type 2 snapshots for churn analysis and account history
- **Production Ready:** Daily refresh schedule with error monitoring and test failures logged
- **Extensible:** Add new sources in 3 steps (sources.yml → stg_* → int_*)

---

*Last updated: April 2026*