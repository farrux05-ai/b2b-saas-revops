
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."revops_test_failures"."accepted_values_dim_accounts_9e6d766e3c96038bf7da6ed12cc1228e"
    
      
    ) dbt_internal_test