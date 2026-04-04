# 🚀 Vercel Deployment - Complete Guide

**Follow these exact steps. Copy-paste exactly as written.**

---

## PART 1: Create Vercel Account & Link GitHub

### Step 1: Create Vercel Account
1. Go to: https://vercel.com/signup
2. Click "Continue with GitHub"
3. Authorize Vercel to access your GitHub

### Step 2: Add Your GitHub Repo to Vercel
1. Go to: https://vercel.com/new
2. Click "Import Project"
3. Paste GitHub URL: `https://github.com/farrux05-ai/b2b-saas-revops`
4. Click "Import"

---

## PART 2: Deploy dbt Docs

### Step 1: Configure dbt docs deployment

**In Vercel Import dialog:**

```
Project Name: b2b-saas-revops-docs
Framework: Other
Root Directory: revops_pipeline/revops_project
```

### Step 2: Add Build Settings

Click "Build and Output Settings":

```
Build Command: dbt docs generate
Output Directory: target
```

### Step 3: Add Environment Variables

Click "Environment Variables":

| Name | Value | Example |
|------|-------|---------|
| `DBT_POSTGRES_HOST` | Your PostgreSQL host | `localhost` or `db.example.com` |
| `DBT_POSTGRES_USER` | PostgreSQL username | `postgres` |
| `DBT_POSTGRES_PASSWORD` | PostgreSQL password | `your_secure_password` |
| `DBT_POSTGRES_PORT` | Port number | `5432` |

**COPY VALUES EXACTLY - NO QUOTES OR SPACES**

### Step 4: Deploy

Click the blue **"Deploy"** button

⏳ Wait 2-3 minutes...

✅ You'll get a URL like: `https://b2b-saas-revops-docs.vercel.app`

**SAVE THIS URL** (your dbt docs)

---

## PART 3: Deploy Evidence Dashboard

### Step 1: Create second Vercel project

Go to: https://vercel.com/new (again)

```
Project Name: b2b-saas-revops-analytics
Framework: Other
Root Directory: revops_pipeline/revops_project/dashboards_v2
```

### Step 2: Add Build Settings

```
Build Command: npm run build
Output Directory: build
```

### Step 3: Environment Variables

**Option A: Using DuckDB (current, simpler)**
- Don't add any environment variables
- Leave empty, click "Deploy"

**Option B: Using PostgreSQL (recommended for production)**
Add these variables:
```
POSTGRES_HOST = your_host
POSTGRES_USER = your_user
POSTGRES_PASSWORD = your_password
```

### Step 4: Deploy

Click blue **"Deploy"** button

⏳ Wait 2-3 minutes...

✅ You'll get a URL like: `https://b2b-saas-revops-analytics.vercel.app`

**SAVE THIS URL** (your Evidence dashboard)

---

## PART 4: Verify Both Are Live

### dbt Docs
- Click your dbt docs URL
- Should see: "B2B SaaS RevOps Pipeline" with documentation
- Click model names, see lineage diagrams

### Evidence Dashboard
- Click your Evidence URL
- Should see: Charts, metrics, dashboard
- Interactive visualizations should load

---

## PART 5: Automatic Daily Updates

✅ **Already set up!** GitHub Actions runs every day at 2 AM UTC:
1. Runs `dbt run` (refresh data)
2. Generates new `dbt docs`
3. Detects GitHub changes
4. **Vercel auto-rebuilds both** ✅

No manual work needed!

---

## ✅ VERIFICATION CHECKLIST

After deployment, verify:

```
☑ dbt docs deployed
☑ Evidence dashboard deployed  
☑ Both URLs working
☑ Can see data in dashboards
☑ GitHub Actions configured (check /actions)
```

---

## 🔧 TROUBLESHOOTING

### "Build failed - dbt: command not found"
**Solution:** 
- Vercel needs Python environment
- Check: Vercel project → Settings → Build & Development
- Runtime: Node.js 18.x is OK (dbt installs via pip)

### "Cannot connect to PostgreSQL"
**Solution:**
- Verify credentials in Vercel environment variables
- Test locally first:
  ```bash
  export DBT_POSTGRES_HOST=your_host
  export DBT_POSTGRES_USER=your_user
  export DBT_POSTGRES_PASSWORD=your_password
  dbt debug
  ```
- If `dbt debug` works locally → Vercel will work with same credentials

### "Evidence shows no data"
**Solution:**
- Make sure `dbt run` was executed locally first
- DuckDB file is in repo (included in git)
- Or configure PostgreSQL as data source

### "404 - Page not found"
**Solution:** 
- Vercel still building (takes 2-3 minutes)
- Check deployment status: Vercel dashboard → Deployments
- Look for green checkmark

---

## 📋 QUICK REFERENCE

```
dbt Docs URL:        https://your-project-docs.vercel.app
Evidence URL:        https://your-project-analytics.vercel.app

GitHub Repo:         https://github.com/farrux05-ai/b2b-saas-revops
GitHub Actions:      /actions (auto run daily)

Env Variables Needed:
  - DBT_POSTGRES_HOST
  - DBT_POSTGRES_USER
  - DBT_POSTGRES_PASSWORD
  - DBT_POSTGRES_PORT
```

---

## 🎯 EXPECTED RESULTS

**After 5 minutes:**
- ✅ dbt docs live and searchable
- ✅ Evidence dashboard with interactive charts
- ✅ Both update automatically daily
- ✅ Zero maintenance needed

**That's it! You're done!** 🎉

For questions: Check DEPLOYMENT.md in repo
