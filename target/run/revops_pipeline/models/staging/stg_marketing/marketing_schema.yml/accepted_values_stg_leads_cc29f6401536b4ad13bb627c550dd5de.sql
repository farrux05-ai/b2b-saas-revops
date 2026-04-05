
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."accepted_values_stg_leads_cc29f6401536b4ad13bb627c550dd5de"
    
      
    ) dbt_internal_test