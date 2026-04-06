
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."revops_test_failures"."relationships_int_account_heal_97926f1d92635c9196b47bd6793e8989"
    
      
    ) dbt_internal_test