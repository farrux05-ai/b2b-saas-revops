
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."revops_test_failures"."accepted_values_stg_ticket_com_9477dd4aaa33d8197216b71ff3ca4016"
    
      
    ) dbt_internal_test