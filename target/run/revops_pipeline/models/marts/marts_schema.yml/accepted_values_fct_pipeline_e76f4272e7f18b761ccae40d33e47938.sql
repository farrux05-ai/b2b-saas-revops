
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."accepted_values_fct_pipeline_e76f4272e7f18b761ccae40d33e47938"
    
      
    ) dbt_internal_test