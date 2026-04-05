
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."accepted_values_int_account_he_ebe8564b4a9587d235c1b6d7c6bb607e"
    
      
    ) dbt_internal_test