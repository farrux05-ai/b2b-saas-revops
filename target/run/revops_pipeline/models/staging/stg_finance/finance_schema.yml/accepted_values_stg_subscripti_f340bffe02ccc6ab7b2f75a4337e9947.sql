
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."revops_test_failures"."accepted_values_stg_subscripti_f340bffe02ccc6ab7b2f75a4337e9947"
    
      
    ) dbt_internal_test