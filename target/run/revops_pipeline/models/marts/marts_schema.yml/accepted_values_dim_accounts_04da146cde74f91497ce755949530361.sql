
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."accepted_values_dim_accounts_04da146cde74f91497ce755949530361"
    
      
    ) dbt_internal_test