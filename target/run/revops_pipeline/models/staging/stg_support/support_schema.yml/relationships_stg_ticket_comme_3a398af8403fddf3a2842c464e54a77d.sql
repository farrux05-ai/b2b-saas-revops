
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."relationships_stg_ticket_comme_3a398af8403fddf3a2842c464e54a77d"
    
      
    ) dbt_internal_test