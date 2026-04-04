# Vercel Deployment Guide

Production uchun **dbt docs** va **Evidence.dev** Vercelga deploy qilish qo'llanmasi.

## Prerequisites

- Vercel account ([vercel.com](https://vercel.com))
- GitHub repo connected to Vercel
- PostgreSQL credentials (or DuckDB in repo)

---

## 1️⃣ dbt Docs Deployment

### Option A: Automatic (Recommended)

**1. Connect GitHub repo to Vercel**
```
1. vercel.com → "Add New Project"
2. Select: farrux05-ai/b2b-saas-revops
3. Framework: Static Site
4. Root Directory: revops_pipeline/revops_project
5. Environment Variables:
   - DBT_POSTGRES_HOST=your_host
   - DBT_POSTGRES_USER=your_user
   - DBT_POSTGRES_PASSWORD=your_password
   - DBT_POSTGRES_PORT=5432
6. Deploy
```

Vercel automatically runs `dbt docs generate` on every push to main.

**2. Custom domain (optional)**
```
Vercel dashboard → Settings → Domains
Add your domain (e.g., docs.revops.dev)
```

### Option B: CLI Deployment

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy from project root
cd revops_pipeline/revops_project
vercel

# For production
vercel --prod
```

---

## 2️⃣ Evidence.dev Deployment

### Setup

**1. Build for production**
```bash
cd dashboards_v2
npm run build
```

**2. Test build locally**
```bash
npm run preview
# Open http://localhost:3000
```

### Deployment Options

**Option A: Vercel Dashboard (Recommended)**

```
1. Create new project in Vercel
2. Import GitHub repo: farrux05-ai/b2b-saas-revops
3. Root Directory: revops_pipeline/revops_project/dashboards_v2
4. Build Command: npm run build
5. Output Directory: build
6. Environment Variables:
   (Choose one option below)
```

**Option B: PostgreSQL as data source**

Update `dashboards_v2/sources/postgres.yml`:
```yaml
name: postgres
type: postgres
host: ${{ env.POSTGRES_HOST }}
port: 5432
database: revops_database
user: ${{ env.POSTGRES_USER }}
password: ${{ env.POSTGRES_PASSWORD }}
```

Add to Vercel environment variables:
- `POSTGRES_HOST`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`

**Option C: DuckDB (for small datasets)**

Keep using `sources/revops/connection.yaml`:
```yaml
filename: ../../duckdb/revops_analytics.duckdb
```

GitHub will include DuckDB file with repo.

---

## 3️⃣ Automated Daily Updates

GitHub Actions automatically runs dbt every day at 2 AM UTC and updates docs.

### Setup GitHub Secrets

1. Go to: https://github.com/farrux05-ai/b2b-saas-revops/settings/secrets/actions
2. Add these secrets:

| Secret | Value |
|--------|-------|
| `POSTGRES_USER` | Your PostgreSQL username |
| `POSTGRES_PASSWORD` | Your PostgreSQL password |
| `POSTGRES_HOST` | localhost or RDS endpoint |
| `POSTGRES_PORT` | 5432 (or your port) |

---

## 4️⃣ Manual Deployments

### Re-build dbt docs
```bash
cd revops_pipeline/revops_project
source dbt-venv/bin/activate
dbt docs generate
git add target/
git commit -m "chore: Update dbt docs"
git push origin main
# Vercel auto-deploys
```

### Re-build Evidence
```bash
cd revops_pipeline/revops_project/dashboards_v2
npm run build
git add build/
git commit -m "chore: Update Evidence dashboard"
git push origin main
# Vercel auto-deploys
```

---

## 5️⃣ URLs After Deployment

| Component | URL | Type |
|-----------|-----|------|
| dbt docs | `https://dbt-docs-xxxx.vercel.app` | Auto-refresh daily |
| Evidence | `https://revops-analytics-xxxx.vercel.app` | Auto-refresh daily |
| GitHub Actions | `https://github.com/.../actions` | View runs |

---

## 6️⃣ Monitoring & Troubleshooting

### Check GitHub Actions status
```bash
# Terminal
gh run list --repo farrux05-ai/b2b-saas-revops

# Or visit:
https://github.com/farrux05-ai/b2b-saas-revops/actions
```

### Check Vercel deployments
```bash
vercel list --prod
vercel inspect <URL>
```

### Common Issues

**"dbt: command not found"**
- Add to Vercel environment: `PATH=/usr/local/bin:/usr/bin:/bin`
- Vercel needs to find dbt executable

**"Cannot connect to PostgreSQL"**
- Verify host/port/credentials in Vercel env vars
- Check database firewall allows Vercel IPs
- Or switch to MotherDuck (PostgreSQL-compatible cloud)

**"Evidence build fails"**
- Run locally: `npm run build`
- Check `npm run sources` works
- Verify DuckDB path or PostgreSQL connection

---

## 7️⃣ Scale to Production

When ready for production:

1. **Custom domains**
   - docs.company.com → dbt docs
   - analytics.company.com → Evidence

2. **Database**
   - Switch from DuckDB to PostgreSQL RDS or MotherDuck
   - Update connection strings in Vercel env vars

3. **CI/CD**
   - Add branch protection rules
   - Require PR reviews before merging to main
   - Status checks for dbt test must pass

4. **Monitoring**
   - Add dbt test email notifications
   - Monitor Vercel analytics dashboard
   - Setup uptime monitoring (Vercel health checks)

---

## 8️⃣ Quick Commands

```bash
# Local preview
cd revops_pipeline/revops_project
dbt docs serve

cd dashboards_v2
npm run dev

# Deploy dbt docs
cd revops_pipeline/revops_project
vercel --prod

# Deploy Evidence
cd dashboards_v2
vercel --prod

# Check status
vercel list --prod

# View logs
vercel logs https://your-app.vercel.app
```

---

For questions or issues, check:
- [Vercel Docs](https://vercel.com/docs)
- [dbt Docs](https://docs.getdbt.com)
- [Evidence Docs](https://docs.evidence.dev)
