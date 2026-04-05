
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."not_null_stg_invoices_is_paid_missing_date"
    
      
    ) dbt_internal_test