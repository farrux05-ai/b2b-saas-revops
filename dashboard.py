import streamlit as st
import pandas as pd
import duckdb
import plotly.express as px
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

st.set_page_config(page_title="RevOps Dashboard", page_icon="📊", layout="wide", initial_sidebar_state="collapsed")

# MODERN B2B STYLE - PROFESSIONAL
st.markdown("""
<style>
    * { font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif; }
    body { color: #111827; background: #ffffff; }
    .main { padding: 2rem; }
    h1 { font-size: 1.35rem; font-weight: 600; letter-spacing: -0.01em; color: #111827; margin-bottom: 0.15rem; }
    h2 { font-size: 0.7rem; font-weight: 600; letter-spacing: 0.08em; text-transform: uppercase; color: #6b7280; margin-top: 2.5rem; margin-bottom: 0.75rem; padding-bottom: 0.5rem; border-bottom: 1px solid #e5e7eb; }
    .page-meta { font-size: 0.8rem; color: #9ca3af; margin-bottom: 2rem; }
</style>
""", unsafe_allow_html=True)

# DATABASE
@st.cache_resource
def get_connection():
    return duckdb.connect('duckdb/revops_analytics.duckdb', read_only=True)

conn = get_connection()

def query(sql):
    try:
        return conn.execute(sql).df()
    except:
        return pd.DataFrame()

# HEADER
st.markdown('<h1>RevOps Dashboard</h1>', unsafe_allow_html=True)
st.markdown('<p class="page-meta">Revenue Intelligence · Pipeline Visibility · Forecasting Accuracy</p>', unsafe_allow_html=True)

# ============================================
# SECTION 1: REVENUE METRICS
# ============================================
st.markdown('<h2>Revenue Summary</h2>', unsafe_allow_html=True)

data = query("""
SELECT
  COUNT(DISTINCT account_id) as total_accounts,
  COUNT(DISTINCT CASE WHEN account_segment = 'Enterprise' THEN account_id END) as enterprise,
  COUNT(DISTINCT CASE WHEN account_segment = 'Mid-Market' THEN account_id END) as midmarket,
  COUNT(DISTINCT CASE WHEN account_segment = 'SMB' THEN account_id END) as smb,
  SUM(open_opportunities) as total_opps,
  SUM(open_tickets) as total_tickets
FROM revops_marts.dim_accounts
""")

if len(data) > 0:
    col1, col2, col3, col4, col5, col6 = st.columns(6)
    with col1:
        st.metric("Total Accounts", f"{data['total_accounts'].values[0]:.0f}")
    with col2:
        st.metric("Enterprise", f"{data['enterprise'].values[0]:.0f}")
    with col3:
        st.metric("Mid-Market", f"{data['midmarket'].values[0]:.0f}")
    with col4:
        st.metric("SMB", f"{data['smb'].values[0]:.0f}")
    with col5:
        st.metric("Total Opps", f"{data['total_opps'].values[0]:.0f}")
    with col6:
        st.metric("Total Tickets", f"{data['total_tickets'].values[0]:.0f}")

st.divider()

# ============================================
# SECTION 2: ACCOUNT HEALTH
# ============================================
st.markdown('<h2>Account Health & Risk</h2>', unsafe_allow_html=True)

health = query("""
SELECT
  COUNT(CASE WHEN open_opportunities > 0 AND open_tickets <= 3 THEN 1 END) as healthy,
  COUNT(CASE WHEN (open_opportunities > 0 AND open_tickets > 3) OR (open_opportunities = 0 AND open_tickets <= 3) THEN 1 END) as at_risk,
  COUNT(CASE WHEN open_opportunities = 0 AND open_tickets > 3 THEN 1 END) as churning
FROM revops_marts.dim_accounts
""")

if len(health) > 0:
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Healthy", f"{health['healthy'].values[0]:.0f}", delta="✓")
    with col2:
        st.metric("At Risk", f"{health['at_risk'].values[0]:.0f}", delta="⚠")
    with col3:
        st.metric("Churning", f"{health['churning'].values[0]:.0f}", delta="✗")

# Health chart
health_df = pd.DataFrame({
    'Status': ['Healthy', 'At Risk', 'Churning'],
    'Count': [health['healthy'].values[0], health['at_risk'].values[0], health['churning'].values[0]]
})
fig = px.pie(health_df, values='Count', names='Status', color_discrete_sequence=['#10b981', '#f59e0b', '#ef4444'])
fig.update_layout(height=350, showlegend=False, margin=dict(l=0, r=0, t=0, b=0))
st.plotly_chart(fig, use_container_width=True)

st.divider()

# ============================================
# SECTION 3: CUSTOMER SEGMENTATION
# ============================================
st.markdown('<h2>Segmentation & Portfolio Health</h2>', unsafe_allow_html=True)

segment = query("""
SELECT
  account_segment as segment,
  COUNT(*) as accounts,
  ROUND(AVG(open_opportunities), 1) as avg_opps,
  ROUND(AVG(open_tickets), 1) as avg_tickets,
  SUM(open_opportunities) as total_opps
FROM revops_marts.dim_accounts
WHERE account_segment IS NOT NULL
GROUP BY account_segment
ORDER BY total_opps DESC
""")

if len(segment) > 0:
    fig = px.bar(segment, x='segment', y='total_opps', color='accounts', 
                color_continuous_scale='Blues', labels={'segment': 'Segment', 'total_opps': 'Total Opportunities'})
    fig.update_layout(height=350, showlegend=False, margin=dict(l=0, r=0, t=0, b=0))
    st.plotly_chart(fig, use_container_width=True)
    st.dataframe(segment, use_container_width=True, height=150)

st.divider()

# ============================================
# SECTION 4: ENGAGEMENT METRICS
# ============================================
st.markdown('<h2>Engagement & Activity</h2>', unsafe_allow_html=True)

engage = query("""
SELECT
  COUNT(DISTINCT CASE WHEN open_opportunities > 0 THEN account_id END) as accounts_with_opps,
  COUNT(DISTINCT CASE WHEN open_tickets > 0 THEN account_id END) as accounts_with_tickets,
  ROUND(AVG(open_opportunities), 2) as avg_opps,
  ROUND(AVG(open_tickets), 2) as avg_tickets,
  ROUND(MAX(open_opportunities), 0) as max_opps
FROM revops_marts.dim_accounts
""")

if len(engage) > 0:
    col1, col2, col3, col4, col5 = st.columns(5)
    with col1:
        st.metric("With Opps", f"{engage['accounts_with_opps'].values[0]:.0f}")
    with col2:
        st.metric("With Tickets", f"{engage['accounts_with_tickets'].values[0]:.0f}")
    with col3:
        st.metric("Avg Opps", f"{engage['avg_opps'].values[0]:.1f}")
    with col4:
        st.metric("Avg Tickets", f"{engage['avg_tickets'].values[0]:.1f}")
    with col5:
        st.metric("Max Opps", f"{engage['max_opps'].values[0]:.0f}")

st.divider()

# ============================================
# SECTION 5: HIGH-PRIORITY ACCOUNTS
# ============================================
st.markdown('<h2>Top Opportunities & Expansion</h2>', unsafe_allow_html=True)

top = query("""
SELECT
  account_name,
  account_segment,
  open_opportunities,
  open_tickets,
  primary_contact_name
FROM revops_marts.dim_accounts
WHERE open_opportunities > 5 OR open_opportunities = 0
ORDER BY open_opportunities DESC
LIMIT 20
""")

if len(top) > 0:
    st.dataframe(top, use_container_width=True, height=350, hide_index=True)
else:
    st.info("No high-priority accounts")

st.divider()

# ============================================
# SECTION 6: CHURN RISK MATRIX
# ============================================
st.markdown('<h2>Churn Risk Assessment</h2>', unsafe_allow_html=True)

risk = query("""
SELECT
  account_name,
  account_segment,
  open_opportunities,
  open_tickets,
  primary_contact_name,
  CASE 
    WHEN open_opportunities = 0 AND open_tickets > 5 THEN 'CRITICAL'
    WHEN open_opportunities = 0 AND open_tickets > 0 THEN 'HIGH'
    WHEN open_tickets > 8 THEN 'MEDIUM'
    ELSE 'LOW'
  END as risk_level
FROM revops_marts.dim_accounts
WHERE open_opportunities = 0 OR open_tickets > 5
ORDER BY open_tickets DESC
LIMIT 25
""")

if len(risk) > 0:
    risk_counts = risk['risk_level'].value_counts()
    fig = px.bar(x=risk_counts.index, y=risk_counts.values,
                color=risk_counts.index,
                color_discrete_map={'CRITICAL': '#dc2626', 'HIGH': '#ea580c', 'MEDIUM': '#ca8a04', 'LOW': '#65a30d'},
                labels={'x': 'Risk Level', 'y': 'Accounts'})
    fig.update_layout(height=300, showlegend=False, margin=dict(l=0, r=0, t=0, b=0))
    st.plotly_chart(fig, use_container_width=True)
    
    # Risk table
    st.subheader("🚨 Accounts Requiring Immediate Action")
    critical = risk[risk['risk_level'].isin(['CRITICAL', 'HIGH'])]
    if len(critical) > 0:
        st.dataframe(critical, use_container_width=True, height=300, hide_index=True)
    else:
        st.success("✅ No critical or high-risk accounts")

st.divider()

# ============================================
# SECTION 7: ACCOUNT PORTFOLIO
# ============================================
st.markdown('<h2>Complete Account Portfolio</h2>', unsafe_allow_html=True)

portfolio = query("""
SELECT
  account_segment,
  COUNT(*) as count,
  COUNT(DISTINCT CASE WHEN open_opportunities > 0 THEN account_id END) as engaged,
  ROUND(AVG(open_opportunities), 1) as avg_opps,
  ROUND(AVG(open_tickets), 1) as avg_support,
  COUNT(DISTINCT CASE WHEN primary_contact_name IS NOT NULL THEN account_id END) as contacts
FROM revops_marts.dim_accounts
GROUP BY account_segment
ORDER BY count DESC
""")

if len(portfolio) > 0:
    st.dataframe(portfolio, use_container_width=True, height=200, hide_index=True)

st.divider()

# ============================================
# FOOTER
# ============================================
st.markdown(f"<p style='text-align: center; color: #d1d5db; font-size: 0.85rem; margin-top: 3rem;'>Revenue Operations Intelligence Platform | Updated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>", unsafe_allow_html=True)
