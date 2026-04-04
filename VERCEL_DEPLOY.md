# Quick Vercel Deployment Checklist

## ✅ Pre-Deployment (Local Setup)

Run this first:
```bash
cd /home/farrux/b2b-saas-project/revops_pipeline/revops_project
chmod +x deploy.sh
./deploy.sh
```

All checks should pass ✓

---

## 🚀 VERCEL DEPLOYMENT (Copy-Paste Instructions)

### PART 1: Create dbt Docs Deployment

**1. Go to:** https://vercel.com/dashboard

**2. Click:** "Add New Project"

**3. Select:** Import your GitHub repository
   - Search: `b2b-saas-revops`
   - Select: `farrux05-ai/b2b-saas-revops`
   - Click: "Import"

**4. Configure Project:**
   - **Project Name:** `dbt-docs` (or any name)
   - **Framework:** (Leave blank or auto-detect)
   - **Root Directory:** `revops_pipeline/revops_project`
   - **Build Command:** `dbt docs generate`
   - **Output Directory:** `target`
   - **Environment Variables:** (See Step 5)

**5. Add Environment Variables:**
   - Click "Add Environment Variable"
   - For EACH variable:
   
   ```
   Name: DBT_POSTGRES_HOST
   Value: your_postgresql_host (e.g., localhost or db.example.com)
   
   Name: DBT_POSTGRES_USER
   Value: your_postgres_username
   
   Name: DBT_POSTGRES_PASSWORD
   Value: your_postgres_password
   
   Name: DBT_POSTGRES_PORT
   Value: 5432
   ```

**6. Click:** "Deploy" ✅

**7. Wait:** 2-3 minutes for deployment

**8. View:** Your dbt docs at the URL shown (e.g., https://dbt-docs-xxx.vercel.app)

---

### PART 2: Create Evidence Dashboard Deployment

**1. Go to:** https://vercel.com/dashboard

**2. Click:** "Add New Project"

**3. Select:** Import your GitHub repository
   - Search: `b2b-saas-revops`
   - Select: `farrux05-ai/b2b-saas-revops`
   - Click: "Import"

**4. Configure Project:**
   - **Project Name:** `revops-analytics` (or any name)
   - **Framework:** (Leave blank or auto-detect)
   - **Root Directory:** `revops_pipeline/revops_project/dashboards_v2`
   - **Build Command:** `npm run build`
   - **Output Directory:** `build`
   - **Environment Variables:** (Skip for now, optional)

**5. Click:** "Deploy" ✅

**6. Wait:** 2-3 minutes for deployment

**7. View:** Your Evidence dashboard at the URL shown (e.g., https://revops-analytics-xxx.vercel.app)

---

## 🔍 Verify Deployment

### ✅ If dbt docs work:
- You should see:
  - Project name, dbt version
  - Model lineage diagram
  - All 22 models listed
  - Search functionality

### ✅ If Evidence dashboard works:
- You should see:
  - MRR metrics
  - Charts and visualizations
  - All 4 dashboard pages
  - No connection errors

---

## ❌ Troubleshooting

### "Build failed" in Vercel

**Check Logs:**
1. Vercel dashboard → Deployments → Click failed deployment
2. Click "Logs" → Find error message

**Common Issues:**

| Error | Fix |
|-------|-----|
| `dbt: command not found` | Vercel needs to install dbt. Check Python version in build logs |
| `Cannot connect to PostgreSQL` | Check environment variables are set correctly in Vercel |
| `database does not exist` | Verify PostgreSQL credentials and ensure database exists |
| `pip: command not found` | Python not available. This is normal - Python auto-installs |

---

## 📊 After Successful Deployment

**Your URLs:**
```
dbt docs:        https://dbt-docs-xxx.vercel.app
Evidence:        https://revops-analytics-xxx.vercel.app
```

**Share with team:**
- Both URLs are public (unless you set password protection in Vercel)
- Dashboards update daily via GitHub Actions

---

## 🔐 Custom Domains (Optional)

In Vercel dashboard:
1. Settings → Domains
2. Add your domain (e.g., `docs.company.com`)
3. Update DNS records (follow Vercel instructions)

---

## 🆘 Need Help?

If still stuck, check:
1. Environment variables set correctly
2. PostgreSQL is accessible from Vercel (may need to whitelist IPs)
3. Database credentials are correct
4. GitHub repo is public (or add deploy key)

For Vercel support: https://vercel.com/docs
