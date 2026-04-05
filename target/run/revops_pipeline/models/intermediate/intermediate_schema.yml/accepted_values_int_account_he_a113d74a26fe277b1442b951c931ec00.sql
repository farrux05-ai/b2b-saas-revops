
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."accepted_values_int_account_he_a113d74a26fe277b1442b951c931ec00"
    
      
    ) dbt_internal_test