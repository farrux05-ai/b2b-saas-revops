-- dim_dates: Universal date dimension table for time-series analysis
-- Grain: one row = one calendar date

with date_spine as (
    select 
        date_trunc('day', generated_date)::date as date_day
    from generate_series(
        '2020-01-01'::date,
        (current_date + interval '2 years')::date,
        '1 day'::interval
    ) as t(generated_date)
)

select
    -- Identity
    date_day,
    date_day as date_id,
    
    -- Year-Quarter-Month
    extract(year from date_day)::int as year,
    extract(quarter from date_day)::int as quarter,
    extract(month from date_day)::int as month,
    to_char(date_day, 'YYYY-MM') as year_month,
    
    -- Week
    extract(week from date_day)::int as week_of_year,
    to_char(date_day, 'YYYY-"W"IW') as year_week,
    
    -- Day
    extract(day from date_day)::int as day_of_month,
    extract(dow from date_day)::int as day_of_week_num,
    case 
        when extract(dow from date_day) = 0 then 'Sunday'
        when extract(dow from date_day) = 1 then 'Monday'
        when extract(dow from date_day) = 2 then 'Tuesday'
        when extract(dow from date_day) = 3 then 'Wednesday'
        when extract(dow from date_day) = 4 then 'Thursday'
        when extract(dow from date_day) = 5 then 'Friday'
        when extract(dow from date_day) = 6 then 'Saturday'
    end as day_of_week_name,
    extract(doy from date_day)::int as day_of_year,
    
    -- Flags
    case when extract(dow from date_day) in (0, 6) then true else false end as is_weekend,
    case 
        when to_char(date_day, 'YYYY-MM-DD') in (
            '2020-01-01', '2020-07-04', '2020-11-26', '2020-12-25',
            '2021-01-01', '2021-07-04', '2021-11-25', '2021-12-25',
            '2022-01-01', '2022-07-04', '2022-11-24', '2022-12-25',
            '2023-01-01', '2023-07-04', '2023-11-23', '2023-12-25',
            '2024-01-01', '2024-07-04', '2024-11-28', '2024-12-25',
            '2025-01-01', '2025-07-04', '2025-11-27', '2025-12-25',
            '2026-01-01', '2026-07-04', '2026-11-26', '2026-12-25'
        ) then true 
        else false 
    end as is_holiday,
    
    -- Fiscal (assuming calendar year = fiscal year)
    extract(year from date_day)::int as fiscal_year,
    extract(quarter from date_day)::int as fiscal_quarter,
    extract(month from date_day)::int as fiscal_month,
    
    current_timestamp as updated_at

from date_spine
order by date_day
