
with

orders_counts as (
    select 
        count(user_id) as nb_users
        ,sum((orders_cnts = 1)::int) as cnts1
        ,sum((orders_cnts = 2)::int) as cnts2
        ,sum((orders_cnts = 3)::int) as cnts3
        ,sum((orders_cnts > 0)::int) as total_orders

    from (
        select 
            address_id
            ,user_id
            ,count(distinct order_id) as orders_cnts

        from {{ source('postgres', 'orders') }}
        -- where address_id = '02331e89-1736-4f12-85b9-ddd62545214b'  -- test
        group by address_id
    )
)

,delivery_times as (
    select 
        (avg(datediff('min', created_at, delivered_at)) / 60)::decimal(5,2) as avg_delivery_time_hr 

    from {{ source('postgres', 'orders') }}
    where STATUS = 'delivered'  -- some delivery times are missing
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

,orders_hr2 as (
    select 
        avg(orders_hr) as avg_orders_hr2  -- 8.62

    from 
        (select 
            count(distinct order_id) over (partition by date_trunc('hour', created_at)) as orders_hr
        from {{ source('postgres', 'orders') }})
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
    nb_users                -- 136
    ,cnts1                  -- 24
    ,cnts2                  -- 46
    ,cnts3                  -- 37
    ,total_orders           -- 136
    ,avg_orders_hr          -- 7.52
    ,avg_orders_hr2         -- 8.62  <<< WHY is it different ? 
    ,avg_delivery_time_hr   -- 93.4
    ,avg_sessions_hr        -- 16.33
    
from orders_counts, delivery_times, orders_hr, orders_hr2, sessions_hr

