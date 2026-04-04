#!/bin/bash
# B2B SaaS RevOps - Automated Vercel Deployment
# Run this script to deploy both dbt docs and Evidence to Vercel

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 B2B SaaS RevOps - Automated Vercel Deployment${NC}"
echo "=================================================="
echo ""

# Check if Vercel CLI is installed
echo -e "${YELLOW}Checking Vercel CLI...${NC}"
if ! command -v vercel &> /dev/null; then
    echo -e "${RED}✗ Vercel CLI not found${NC}"
    echo "Install with: npm install -g vercel"
    echo "Then run this script again"
    exit 1
fi
echo -e "${GREEN}✓ Vercel CLI found${NC}"

# Step 1: Verify local builds
echo ""
echo -e "${YELLOW}Step 1: Verifying local builds...${NC}"
cd "$PROJECT_ROOT"

# Activate venv and build dbt docs
source dbt-venv/bin/activate
dbt docs generate
echo -e "${GREEN}✓ dbt docs generated${NC}"

# Build Evidence
cd "$PROJECT_ROOT/dashboards_v2"
npm run build > /dev/null 2>&1
echo -e "${GREEN}✓ Evidence dashboard built${NC}"

# Step 2: Ask for Vercel credentials
echo ""
echo -e "${YELLOW}Step 2: Vercel Authentication${NC}"
echo "You need to be logged in to Vercel"
echo "If not logged in, this will open browser auth"
vercel login

# Step 3: Deploy dbt docs
echo ""
echo -e "${YELLOW}Step 3: Deploying dbt docs...${NC}"
cd "$PROJECT_ROOT"

# Check if project already linked
if [ ! -d ".vercel" ]; then
    echo "First deployment - linking project"
    vercel link --yes --scope=farrux05-ai
fi

# Set environment variables
echo ""
echo -e "${YELLOW}Setting environment variables...${NC}"
read -p "Enter PostgreSQL host (localhost): " PG_HOST
PG_HOST=${PG_HOST:-localhost}

read -p "Enter PostgreSQL user: " PG_USER
read -sp "Enter PostgreSQL password: " PG_PASS
echo ""

read -p "Enter PostgreSQL port (5432): " PG_PORT
PG_PORT=${PG_PORT:-5432}

# Create .vercelignore for dbt docs
cat > .vercelignore << 'EOF'
dashboards_v2/
dbt-venv/
.git/
node_modules/
.dbt/
duckdb/
.env
EOF

# Deploy dbt docs
echo -e "${YELLOW}Deploying dbt docs to Vercel...${NC}"
vercel deploy \
  --prod \
  --env DBT_POSTGRES_HOST="$PG_HOST" \
  --env DBT_POSTGRES_USER="$PG_USER" \
  --env DBT_POSTGRES_PASSWORD="$PG_PASS" \
  --env DBT_POSTGRES_PORT="$PG_PORT" \
  --meta=target=target

DBT_URL=$(vercel list --prod | grep "target" | awk '{print $(NF-1)}')
echo -e "${GREEN}✓ dbt docs deployed to: $DBT_URL${NC}"

# Step 4: Deploy Evidence
echo ""
echo -e "${YELLOW}Step 4: Deploying Evidence dashboard...${NC}"
cd "$PROJECT_ROOT/dashboards_v2"

# Create .vercelignore for Evidence
cat > .vercelignore << 'EOF'
../dbt-venv/
../.git/
../duckdb/
../.env
EOF

# Deploy Evidence
vercel deploy \
  --prod \
  --meta=target=evidence

EVIDENCE_URL=$(vercel list --prod | grep "dashboards_v2\|evidence" | tail -1 | awk '{print $(NF-1)}')
echo -e "${GREEN}✓ Evidence deployed to: $EVIDENCE_URL${NC}"

# Summary
echo ""
echo "=================================================="
echo -e "${GREEN}✓ Deployment Complete!${NC}"
echo ""
echo -e "${BLUE}📊 Your dashboards are now live:${NC}"
echo -e "  dbt Docs:    ${GREEN}https://$DBT_URL${NC}"
echo -e "  Evidence:    ${GREEN}https://$EVIDENCE_URL${NC}"
echo ""
echo "✅ Both services automatically update daily via GitHub Actions!"
