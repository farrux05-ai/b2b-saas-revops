
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."accepted_values_fct_revenue_442950dd28b73d58f9100d172033787d"
    
      
    ) dbt_internal_test