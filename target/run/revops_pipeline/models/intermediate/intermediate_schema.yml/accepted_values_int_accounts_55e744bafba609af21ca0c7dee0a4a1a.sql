
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."revops_test_failures"."accepted_values_int_accounts_55e744bafba609af21ca0c7dee0a4a1a"
    
      
    ) dbt_internal_test