
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."accepted_values_stg_payments_0a68bd20fe58431edb2dbf71cff25165"
    
      
    ) dbt_internal_test