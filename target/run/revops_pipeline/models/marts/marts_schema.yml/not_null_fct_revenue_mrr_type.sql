
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."not_null_fct_revenue_mrr_type"
    
      
    ) dbt_internal_test