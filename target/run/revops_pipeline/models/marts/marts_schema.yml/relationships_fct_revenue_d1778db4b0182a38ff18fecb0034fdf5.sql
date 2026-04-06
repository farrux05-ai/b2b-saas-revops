
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."revops_test_failures"."relationships_fct_revenue_d1778db4b0182a38ff18fecb0034fdf5"
    
      
    ) dbt_internal_test