
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."relationships_stg_subscription_6d9aa4b9290d1a24165a838ea16ef302"
    
      
    ) dbt_internal_test