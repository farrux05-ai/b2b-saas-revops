
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."revops_test_failures"."accepted_values_stg_campaigns_bff59d93f0ab8bc61d3150c6ef67a48c"
    
      
    ) dbt_internal_test