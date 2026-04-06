-- tests/assert_health_status_logic_consistent.sql
--
-- Objective: Ensure health_status logic is internally consistent
--   churned  → subscription_status = cancelled
--   at_risk  → past_due, urgent ticket, overdue invoice, or high open tickets/response times
--   inactive → last_active_at > inactive_days_threshold
--   healthy  → no risk signals present
--
-- Passes if 0 rows returned

with health as (
    select
        account_id,
        account_name,
        health_status,
        subscription_status,
        overdue_invoices,
        urgent_open_tickets,
        last_active_at
        avg_response_hours,
        open_tickets
        --  risk_score removed — not in model
    from {{ ref('int_account_health') }}
),

violations as (
    select
        account_id,
        account_name,
        health_status,
        'churned_but_not_cancelled' as violation_type
    from health
    where health_status = 'churned'
      and subscription_status != 'cancelled'

    union all

    select
        account_id,
        account_name,
        health_status,
        'healthy_but_has_risk' as violation_type
    from health
    where health_status = 'healthy'
      and (
          overdue_invoices > 0
          or urgent_open_tickets > 0
          or subscription_status = 'past_due'
          or avg_response_hours > {{ var('at_risk_response_hours') }}
          or open_tickets > {{ var('at_risk_open_tickets') }}
          or (last_active_at is not null and last_active_at < now() - interval '{{ var("at_risk_days_since_active") }} days')
      )

    union all

    select
        account_id,
        account_name,
        health_status,
        'inactive_but_recent_activity' as violation_type
    from health
    where health_status = 'inactive'
      and last_active_at >= now() - interval '{{ var("inactive_days_threshold") }} days'
)

select * from violations
