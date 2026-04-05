-- tests/assert_health_status_logic_consistent.sql
--
-- Maqsad: health_status mantig'i to'g'ri ishlayaptimi?
--   churned  → subscription_status = cancelled bo'lishi kerak
--   at_risk  → past_due, urgent ticket yoki overdue invoice bo'lishi kerak
--   inactive → last_active_at > 30 kun bo'lishi kerak
--   healthy  → hech qaysi xavf signali bo'lmasligi kerak
--
-- Test muvaffaqiyatli = 0 qator qaytadi

with health as (
    select
        account_id,
        account_name,
        health_status,
        subscription_status,
        overdue_invoices,
        urgent_open_tickets,
        last_active_at
        -- ❌ risk_score olib tashlandi — model da yo'q
    from "revops_database"."raw_int"."int_account_health"
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
      )

    union all

    select
        account_id,
        account_name,
        health_status,
        'inactive_but_recent_activity' as violation_type
    from health
    where health_status = 'inactive'
      and last_active_at >= now() - interval '30 days'
)

select * from violations