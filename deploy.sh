#!/bin/bash
# B2B SaaS RevOps - Deployment Helper Script
# This script prepares your project for Vercel deployment

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DBT_DIR="$PROJECT_ROOT"
DASHBOARDS_DIR="$PROJECT_ROOT/dashboards_v2"

echo "🚀 B2B SaaS RevOps - Vercel Deployment Helper"
echo "=============================================="
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Verify dbt connection
echo "${YELLOW}Step 1: Verifying dbt connection...${NC}"
cd "$DBT_DIR"
source dbt-venv/bin/activate
if dbt debug > /dev/null 2>&1; then
    echo -e "${GREEN}✓ dbt connection OK${NC}"
else
    echo -e "${RED}✗ dbt connection failed${NC}"
    echo "  Make sure PostgreSQL is running and ~/.dbt/profiles.yml is configured"
    exit 1
fi

# Step 2: Build dbt docs
echo ""
echo "${YELLOW}Step 2: Building dbt documentation...${NC}"
dbt docs generate
if [ -f "$DBT_DIR/target/index.html" ]; then
    echo -e "${GREEN}✓ dbt docs generated${NC}"
else
    echo -e "${RED}✗ Failed to generate dbt docs${NC}"
    exit 1
fi

# Step 3: Verify Evidence sources
echo ""
echo "${YELLOW}Step 3: Verifying Evidence datasources...${NC}"
cd "$DASHBOARDS_DIR"
npm install > /dev/null 2>&1
if npm run sources > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Evidence datasources connected${NC}"
else
    echo -e "${YELLOW}⚠ Evidence datasources check (non-blocking)${NC}"
fi

# Step 4: Build Evidence
echo ""
echo "${YELLOW}Step 4: Building Evidence dashboard...${NC}"
npm run build > /dev/null 2>&1
if [ -d "$DASHBOARDS_DIR/build" ]; then
    echo -e "${GREEN}✓ Evidence build successful${NC}"
else
    echo -e "${RED}✗ Evidence build failed${NC}"
    exit 1
fi

# Step 5: Check Git status
echo ""
echo "${YELLOW}Step 5: Checking Git status...${NC}"
cd "$PROJECT_ROOT"
if git status | grep -q "working tree clean\|nothing to commit"; then
    echo -e "${GREEN}✓ Working directory clean${NC}"
else
    echo -e "${YELLOW}⚠ Uncommitted changes detected${NC}"
    echo "  Run: git status"
fi

# Summary
echo ""
echo "=============================================="
echo -e "${GREEN}✓ All checks passed!${NC}"
echo ""
echo "📋 NEXT STEPS FOR VERCEL DEPLOYMENT:"
echo ""
echo "1. Go to: https://vercel.com"
echo ""
echo "2. For DBT DOCS:"
echo "   - Import GitHub repo: farrux05-ai/b2b-saas-revops"
echo "   - Root Directory: revops_pipeline/revops_project"
echo "   - Build Command: dbt docs generate"
echo "   - Output Directory: target"
echo ""
echo "3. For EVIDENCE DASHBOARD:"
echo "   - Import GitHub repo: farrux05-ai/b2b-saas-revops"
echo "   - Root Directory: revops_pipeline/revops_project/dashboards_v2"
echo "   - Build Command: npm run build"
echo "   - Output Directory: build"
echo ""
echo "4. Add Environment Variables (in Vercel dashboard):"
echo "   - DBT_POSTGRES_HOST=<your_host>"
echo "   - DBT_POSTGRES_USER=<your_user>"
echo "   - DBT_POSTGRES_PASSWORD=<your_password>"
echo "   - DBT_POSTGRES_PORT=5432"
echo ""
echo "5. Deploy!"
echo ""
echo "✅ Your project is ready for Vercel deployment!"
