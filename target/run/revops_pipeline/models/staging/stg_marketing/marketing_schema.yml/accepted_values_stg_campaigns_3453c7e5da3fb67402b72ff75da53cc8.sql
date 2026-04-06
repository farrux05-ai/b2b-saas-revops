
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."revops_test_failures"."accepted_values_stg_campaigns_3453c7e5da3fb67402b72ff75da53cc8"
    
      
    ) dbt_internal_test