
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."revops_test_failures"."relationships_stg_opportunitie_2eb173b9aa9395d0b28f3ef711ead85b"
    
      
    ) dbt_internal_test