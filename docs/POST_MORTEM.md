# Project Post Mortem — RevOps dbt Pipeline

This is a living document. Every time we discover a bug, misconfiguration, or design flaw during the review of each layer (Staging → Intermediate → Marts), we record it here.

---

## Layer 0: Configuration & Architecture

### PM-001 · Hardcoded Credentials in profiles.yml
**Severity:** Critical  
**Layer:** Configuration  
**Status:** Fixed

Database credentials (host, user, password, dbname, port) were written directly inside `profiles.yml` as plain text. This file was committed to Git, meaning anyone with repository access could read the production database password.

**Fix:** All credentials moved to `~/.zshrc` as environment variables. `profiles.yml` now reads them via `{{ env_var('DBT_POSTGRES_*') }}`.

**Rule to remember:** Secrets never go in code. If a value would be embarrassing to see on GitHub, it belongs in an environment variable.

---

### PM-002 · Inconsistent Schema Naming (marts_marts)
**Severity:** High  
**Layer:** Configuration  
**Status:** Fixed

The dbt schema naming convention was inconsistent. The marts layer was being materialized into a schema called `marts_marts` instead of something logical. This caused Evidence.dev dashboards to fail because they were querying schema names that did not match what dbt produced.

**Fix:** `dbt_project.yml` and `profiles.yml` updated so that all three layers use a uniform, readable prefix: `revops_staging`, `revops_int`, `revops_marts`. Dashboard SQL files updated to match.

**Rule to remember:** Schema names should describe the data layer, not repeat the folder structure. Define the naming convention once in `dbt_project.yml` and never override it per model.

---

### PM-003 · dbt source freshness incompatible with postgres_scan() macro
**Severity:** Medium  
**Layer:** Configuration / Architecture  
**Status:** Accepted (documented, not changed)

The project uses a custom `postgres_source()` macro wrapping DuckDB's `postgres_scan()` to read raw Postgres data at query time. This works for `dbt run`. However, `dbt source freshness` does not invoke custom macros — it queries the catalog name defined in `sources.yml` directly. Because Postgres is not `ATTACH`ed to DuckDB as a full catalog, the command fails with `Binder Error: Catalog "revops_database" does not exist`.

**Fix:** Decision made to skip `dbt source freshness` in this hybrid setup. Freshness monitoring is delegated to the ingestion layer (e.g. Fivetran/Airbyte). Detailed in `TECHNICAL.md → Pitfall 5`.

**Rule to remember:** When using a non-standard adapter pattern (like postgres_scan instead of native sources), verify which dbt commands are affected. Not every dbt command is macro-aware.

---

### PM-004 · Non-English comments and descriptions throughout the project
**Severity:** Low  
**Layer:** Configuration / Documentation  
**Status:** Fixed

The majority of YAML descriptions, SQL comments, and documentation files were written in Uzbek. This makes the project inaccessible to any collaborator who does not speak Uzbek and is inconsistent with standard professional practice in data engineering.

**Fix:** All comments, descriptions, and documentation translated to English. Language standard for this project is now English-only.

---

## Layer 1: Staging

### PM-005 · Over-engineered tests — not_null on boolean flag columns
**Severity:** Medium  
**Layer:** Staging / schema YAMLs  
**Status:** Fixed

160+ tests were defined across staging schema files. A significant portion of these were `not_null` tests on columns like `is_amount_null`, `is_owner_null`, `is_close_date_past`. These columns are derived directly from boolean SQL expressions (e.g. `amount IS NULL AS is_amount_null`). A boolean expression in SQL always returns `TRUE` or `FALSE` — it physically cannot produce NULL. Testing `not_null` on them wastes compute on every `dbt test` run and adds noise to test output.

**Fix:** Removed all `not_null` tests from boolean flag columns and derived row-number columns. Kept only: primary keys (`not_null + unique`), foreign keys (`relationships`), and business-critical status fields (`accepted_values`).

**Rule to remember:** Only test what can actually fail. Boolean expressions and `ROW_NUMBER()` outputs cannot be NULL. Testing them is cargo-cult testing — it looks thorough but catches nothing.

---

### PM-006 · Silent bug — email_issue values mismatched between SQL and YAML test
**Severity:** High  
**Layer:** Staging / stg_leads  
**Status:** Fixed

In `stg_leads.sql`, the `email_issue` classification produced two values that did not match what the `accepted_values` test in `marketing_schema.yml` was expecting:

| Column | SQL produced | YAML expected | Result |
|---|---|---|---|
| `email_issue` | `'invalid_form'` | `'invalid_format'` | Always WARN |
| `email_issue` | `'personal_email'` | `'personal_domain'` | Always WARN |

The test was always in a WARN state, but because severity was set to `warn` instead of `error`, the pipeline never failed. The Marketing team would have received wrong email segment labels in dashboards without any alert.

**Fix:** Corrected both string values in `stg_leads.sql` to match the documented accepted values: `'invalid_format'` and `'personal_domain'`.

**Rule to remember:** When you define an `accepted_values` test, the strings in the test must be character-for-character identical to what the SQL produces. Always verify them together. A WARN that is always firing is a bug in disguise.

---

### PM-007 · Truncated comment in stg_contacts.sql
**Severity:** Low  
**Layer:** Staging / stg_contacts  
**Status:** Fixed

A comment on line 22 of `stg_contacts.sql` was cut off mid-sentence:
```sql
-- primary_row_num > 1 = one account one
```
The intent of the `ROW_NUMBER()` window function was unclear to anyone reading the file for the first time.

**Fix:** Comment replaced with a complete, accurate explanation:
```sql
-- Detect accounts with more than one contact marked as primary.
-- primary_row_num > 1 means a duplicate primary contact exists for that account.
```

**Rule to remember:** Incomplete comments are worse than no comments — they suggest the author stopped thinking halfway through. If a comment is worth starting, finish it.

---

### PM-008 · Legacy test syntax — tests: instead of data_tests:
**Severity:** Low  
**Layer:** All staging schema YAMLs  
**Status:** Fixed

All schema YAML files used the old `tests:` key for column-level data tests. Starting in dbt v1.8, this key was deprecated in favour of `data_tests:` to distinguish data quality tests from unit tests. The project is running dbt v1.11.7.

**Fix:** All occurrences of `tests:` under column definitions replaced with `data_tests:` across all 8 schema files using an automated script.

**Rule to remember:** When upgrading dbt versions (or starting a new project), always check the migration guide for deprecated syntax. Running a deprecated key produces a warning on every `dbt run`, adding noise that hides real warnings.

---

## Layer 2: Intermediate

### PM-009 · NULL trap on boolean filter in int_accounts
**Severity:** High  
**Layer:** Intermediate / int_accounts  
**Status:** Fixed

The query filtered subscriptions with `where not is_status_conflict`. Because SQL's three-valued logic evaluates `NOT NULL` as `NULL`, any row where `is_status_conflict` was NULL was being silently dropped from the dataset, causing accounts to lose their active subscriptions.

**Fix:** Changed the filter to `where not coalesce(is_status_conflict, false)` to safely handle NULL flags.

**Rule to remember:** Never use `NOT boolean_column` without a `COALESCE` if the column isn't strictly guaranteed to be non-null. 

---

### PM-010 · Double table scan of stg_product_users causing performance drag
**Severity:** Medium (Performance)  
**Layer:** Intermediate / int_account_health  
**Status:** Fixed

The `stg_product_users` model was read once in the `users` CTE for aggregations, and a second time in the `events` CTE. Unless materialized as a table/view beforehand, dbt runs would execute the staging logic twice, causing unnecessary warehouse reads.

**Fix:** Created a `raw_users` CTE at the top and referenced it in both downstream CTEs (`users` and `events`) to ensure a single logical read.

**Rule to remember:** If you need the same staging model multiple times in the same intermediate query, wrap it in a root CTE and reference that CTE.

---

### PM-011 · Silent loss of campaign_id on soft-deleted campaigns
**Severity:** High  
**Layer:** Intermediate / int_contacts  
**Status:** Fixed

The model joined `first_touch` with `campaigns` to pull campaign metadata. It mapped the final campaign ID using `cmp.id as first_campaign_id`. If a campaign was soft-deleted or missing from the `campaigns` table, `cmp.id` returned NULL, silently wiping out the tracking ID even though `first_touch.campaign_id` had the correct raw ID. 

**Fix:** Used `coalesce(cmp.id, ft.campaign_id) as first_campaign_id` to fall back to the raw tracking ID if the dimension record was missing.

**Rule to remember:** When joining a fact/touch layer to a dimension layer via LEFT JOIN, always coalesce the dimension ID with the fact ID to preserve tracking data when dimension records go missing.

---

### PM-012 · Flawed logic for 'inactive' health status
**Severity:** Medium (Logic)  
**Layer:** Intermediate / int_account_health  
**Status:** Fixed

An account was marked `inactive` if it hadn't been logged into for 30 days AND its `subscription_status = 'active'`. This meant that `trialing` users who abandoned the product were falsely classified as `healthy` instead of `inactive`.

**Fix:** Expanded the logic to `and a.subscription_status in ('active', 'trialing')`.

**Rule to remember:** When defining business logic exclusions based on statuses, always ask "what other statuses exist?" (active vs past_due vs trialing vs cancelled).

---

### PM-013 · Incorrect referential integrity assumptions in schema tests
**Severity:** Medium  
**Layer:** Intermediate / intermediate_schema.yml  
**Status:** Fixed

`int_contacts` applied a `not_null` test on `account_id`, assuming all contacts belong to an account. In reality, standalone contacts (not yet associated with an account) can exist. Furthermore, despite being heavily join-dependent, none of the intermediate models (`int_contacts`, `int_account_health`) had `relationships` tests enforcing that their `account_id` actually existed in the `int_accounts` anchor model.

**Fix:** Removed the strict `not_null` test from `int_contacts.account_id` and added `relationships` tests mapping `account_id` directly to `ref('int_accounts')`.

**Rule to remember:** Test the relationships between your models, not just their staging counterparts. If a model relies on an anchor model, add a relationship test.

---

## Layer 3: Marts
*To be filled as we review this layer.*
