
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."revops_test_failures"."accepted_values_fct_revenue_156122f159bd04905790a17457a6f810"
    
      
    ) dbt_internal_test