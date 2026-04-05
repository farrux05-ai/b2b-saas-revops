
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."accepted_values_dim_accounts_71225675d7d4de61531dea016b1696cc"
    
      
    ) dbt_internal_test