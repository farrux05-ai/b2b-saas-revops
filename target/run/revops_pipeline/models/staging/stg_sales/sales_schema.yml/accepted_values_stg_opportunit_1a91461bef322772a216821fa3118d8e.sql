
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."revops_test_failures"."accepted_values_stg_opportunit_1a91461bef322772a216821fa3118d8e"
    
      
    ) dbt_internal_test