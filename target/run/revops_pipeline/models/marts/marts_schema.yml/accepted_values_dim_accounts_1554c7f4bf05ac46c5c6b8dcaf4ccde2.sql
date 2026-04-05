
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."accepted_values_dim_accounts_1554c7f4bf05ac46c5c6b8dcaf4ccde2"
    
      
    ) dbt_internal_test