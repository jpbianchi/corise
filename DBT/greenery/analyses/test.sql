
with
orders as (
select 
    address_id
    -- order_id
    ,count(distinct order_id) as orders_cnts
    -- ,datediff('min', created_at, delivered_at) as delivery_time
    -- ,created_at
    -- ,delivered_at

from {{ source('postgres', 'orders') }}
-- where address_id = '02331e89-1736-4f12-85b9-ddd62545214b'
group by address_id

-- having orders_cnts = 1
-- order by address_id
)

,orders_counts as (
select 
    count(distinct address_id) as nb_users
    ,sum((orders_cnts =1)::int) as cnts1
    ,sum((orders_cnts =2)::int) as cnts2
    ,sum((orders_cnts =3)::int) as cnts3
    ,sum((orders_cnts > 0)::int) as total_orders

from orders 
)

,delivery_times as (
    select 
        (avg(datediff('min', created_at, delivered_at)) / 60)::decimal(5,2) as avg_delivery_time_hr  -- WARNING: some delivery times are empty

    from {{ source('postgres', 'orders') }}
    -- where delivered_at 'is not None'
)

,orders as (
    select 

        count(distinct order_id) as orders_hour

    from {{ source('postgres', 'orders') }}
    group by date_trunc('hour', created_at)  -- removes mins and seconds
)

, orders_hr as (
    select 
        avg(orders_hour) as avg_orders_hr
    
    from orders
)

,sessions as (
    select 
        count(distinct session_id) as sessions_hour

    from {{ source('postgres', 'events') }}   
    group by date_trunc('hour', created_at) 
)

, sessions_hr as (
    select
        avg(sessions_hour) as avg_sessions_hr
    from sessions
)
select 
    nb_users
    ,cnts1
    ,cnts2
    ,cnts3
    ,total_orders
    ,avg_orders_hr
    ,avg_delivery_time_hr
    ,avg_sessions_hr
    
from orders_counts, delivery_times, orders_hr, sessions_hr

