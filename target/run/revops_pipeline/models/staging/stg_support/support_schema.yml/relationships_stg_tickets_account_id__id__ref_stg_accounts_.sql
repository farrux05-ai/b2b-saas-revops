
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
        select *
        from "revops_analytics"."revops_test_failures"."relationships_stg_tickets_account_id__id__ref_stg_accounts_"
    
      
    ) dbt_internal_test