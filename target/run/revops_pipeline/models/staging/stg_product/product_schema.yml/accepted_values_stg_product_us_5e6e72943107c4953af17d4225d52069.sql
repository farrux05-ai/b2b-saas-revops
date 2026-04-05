
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."accepted_values_stg_product_us_5e6e72943107c4953af17d4225d52069"
    
      
    ) dbt_internal_test