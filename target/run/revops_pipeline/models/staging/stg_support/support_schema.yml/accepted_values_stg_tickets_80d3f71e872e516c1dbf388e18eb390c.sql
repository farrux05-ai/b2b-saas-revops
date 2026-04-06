
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."revops_test_failures"."accepted_values_stg_tickets_80d3f71e872e516c1dbf388e18eb390c"
    
      
    ) dbt_internal_test