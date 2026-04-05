
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."accepted_values_stg_activities_18300eb86a0108a2e3bf87be575b46eb"
    
      
    ) dbt_internal_test