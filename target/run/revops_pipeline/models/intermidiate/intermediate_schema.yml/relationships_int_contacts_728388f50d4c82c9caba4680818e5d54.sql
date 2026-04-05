
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."marts_test_failures"."relationships_int_contacts_728388f50d4c82c9caba4680818e5d54"
    
      
    ) dbt_internal_test