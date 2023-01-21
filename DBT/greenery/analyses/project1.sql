
with

users_cnt as (
    select 
        count(distinct user_id) as nb_users

    from {{ source('postgres', 'users') }}
)

,orders_counts as (
    select 
        sum((orders_cnts = 1)::int) as cnts1
        ,sum((orders_cnts = 2)::int) as cnts2
        ,sum((orders_cnts = 3)::int) as cnts3
        ,sum((orders_cnts > 0)::int) as total_orders

    from (
        select 
            user_id
            ,count(distinct order_id) as orders_cnts

        from {{ source('postgres', 'orders') }}
        -- where address_id = '02331e89-1736-4f12-85b9-ddd62545214b'  -- test
        group by user_id
    )
)

,delivery_times as (
    select 
        (avg(datediff('min', created_at, delivered_at)) / 60)::decimal(5,2) as avg_delivery_time_hr 

    from {{ source('postgres', 'orders') }}
    where STATUS = 'delivered'  -- some delivery times are missing because it's not delivered yet
)


,orders_hr as (
    select 
        avg(orders_hr) as avg_orders_hr  -- 7.52

    from 
        (select 
            count(distinct order_id) as orders_hr
        from {{ source('postgres', 'orders') }}
        group by date_trunc('hour', created_at) )    -- removes mins and seconds
)

,sessions_hr as (
    select
        avg(sessions_hour) as avg_sessions_hr

    from (
        select 
            count(distinct session_id) as sessions_hour

        from {{ source('postgres', 'events') }}   
        group by date_trunc('hour', created_at)
    )
)

select 
    nb_users                -- 130
    ,cnts1                  -- 25
    ,cnts2                  -- 28
    ,cnts3                  -- 34
    ,total_orders           -- 124
    ,avg_orders_hr          -- 7.52
    ,avg_delivery_time_hr   -- 93.4
    ,avg_sessions_hr        -- 16.33
    
from users_cnt, orders_counts, delivery_times, orders_hr, sessions_hr

