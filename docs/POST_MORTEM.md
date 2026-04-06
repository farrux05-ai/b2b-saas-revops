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
*To be filled as we review this layer.*

---

## Layer 3: Marts
*To be filled as we review this layer.*
