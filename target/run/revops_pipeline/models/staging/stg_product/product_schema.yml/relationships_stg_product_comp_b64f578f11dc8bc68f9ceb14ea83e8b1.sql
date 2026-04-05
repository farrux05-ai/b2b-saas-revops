
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."relationships_stg_product_comp_b64f578f11dc8bc68f9ceb14ea83e8b1"
    
      
    ) dbt_internal_test