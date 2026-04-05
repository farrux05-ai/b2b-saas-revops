
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."accepted_values_stg_product_co_963fd71550c1b8f2a2a824f061311d2c"
    
      
    ) dbt_internal_test