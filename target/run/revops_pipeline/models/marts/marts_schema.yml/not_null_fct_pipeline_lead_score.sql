
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."revops_test_failures"."not_null_fct_pipeline_lead_score"
    
      
    ) dbt_internal_test