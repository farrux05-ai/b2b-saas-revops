# Deployment Guide: RevOps Pipeline & Analytics

This guide provides a "Modeling-First" approach to deploying your dbt documentation and Evidence dashboards. Since this project focuses on data modeling rather than extraction/orchestration, we prioritize simplicity and manual builds over complex CI/CD pipelines.

---

## 1. dbt Documentation Deployment

The dbt documentation consists of static HTML and JSON files. You have two main options:

### Option A: Single-File HTML (Recommended for Sharing)
Generating a single HTML file is the easiest way to share the full documentation via email or Slack without needing a server.

1.  Navigate to your dbt project:
    ```bash
    cd revops_pipeline/revops_project
    ```
2.  Install the `dbt-docs-to-single-file` tool:
    ```bash
    pip install dbt-docs-to-single-file
    ```
3.  Generate the docs and merge them into one file:
    ```bash
    dbt docs generate
    python -m dbt_docs_to_single_file --target-dir target --output docs.html
    ```
4.  **Result**: You now have a `docs.html` file that you can open in any browser or send to colleagues.

### Option B: Static Site Hosting (Vercel/Netlify)
If you want a live URL for your docs:
1.  Generate docs: `dbt docs generate`.
2.  Deploy the `target/` folder as a static site.
    - **Surge**: `npx surge target/`
    - **Vercel**: `vercel target` (select "Other" as the framework).

---

## 2. Evidence Dashboard Deployment

Evidence requires a build step to bake your DuckDB data into the dashboard.

### Option A: Evidence Cloud (Easiest)
Evidence Cloud handles builds and data refreshing automatically.
1.  Push your code to GitHub.
2.  Connect your repository to [Evidence Cloud](https://evidence.dev/cloud).
3.  In Settings, configure your connection to pointing to your DuckDB file (or upload it).
4.  **Note**: Since your DuckDB file is built locally, you may need to commit a snapshot of it (if size allows) or provide it via a URL.

### Option B: Vercel (Manual Build)
If you prefer Vercel, the key is ensuring the DuckDB file is available during the build.

1.  **DuckDB Path**: Ensure `sources/revops/connection.yaml` uses a relative path that Vercel can resolve:
    ```yaml
    filename: ../../duckdb/revops_analytics.duckdb
    ```
2.  **Commit DuckDB**: For a "modeling-only" project, you can commit the DuckDB file to Git (remove from `.gitignore`). 
    > [!WARNING]
    > Only do this if the file is <100MB. For larger files, use LFS or a cloud bucket.
3.  **Vercel Configuration**:
    - Build Command: `npm run build`
    - Output Directory: `build`
    - Install Command: `npm install`

---

## 3. Maintenance & Updates

Since you are not using GitHub Workflows for orchestration:
1.  **Update Data**: Run `dbt run` and `dbt snapshot` locally.
2.  **Update Docs**: Run `dbt docs generate`.
3.  **Update Dashboard**: Run `npm run build` in `dashboards_v2`.
4.  **Push**: Commit and push the updated `target/` and `.duckdb` files (if committed) to refresh the live sites.

---

## Troubleshooting Vercel Errors

If you see "Error: DuckDB file not found":
- Check the relative path in `connection.yaml`.
- Ensure the file is not being excluded by `.gitignore` during the `git push`.
- Check if Vercel has permissions to read the parent directory if the DuckDB is outside the Evidence folder. (Moving the DuckDB file *inside* the Evidence folder structure is often the safest fix).
