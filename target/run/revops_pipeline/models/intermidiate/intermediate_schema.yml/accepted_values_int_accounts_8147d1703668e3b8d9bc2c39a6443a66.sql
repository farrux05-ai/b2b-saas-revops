
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."accepted_values_int_accounts_8147d1703668e3b8d9bc2c39a6443a66"
    
      
    ) dbt_internal_test