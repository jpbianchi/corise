

with
orders as (
    select 
        address_id
        ,count(distinct order_id) over (partition by address_id) as orders_cnts
        ,count(distinct order_id) over (partition by extract(hour from created_at)) as orders_hour  -- it is wrong to mix with address_id 
        ,datediff('min', created_at, delivered_at) as delivery_time

    from {{ source('postgres', 'orders')}}
)

,sessions as (
    select 
        extract(hour from created_at) as hour
        ,count(distinct session_id) over (partition by hour) as avg_sessions_hour
    from {{ source('postgres', 'events')}}    
)

select 
    address_id
    ,orders_cnts
    ,orders_hour
    ,delivery_time
from orders
order by address_id

-- select
--     count(distinct address_id) as nb_users -- 136
--     ,sum(case when orders_cnts = 1 then 1 else 0 end) as orders_cnt1  -- 24  should be 24
--     ,sum(case when orders_cnts = 2 then 1 else 0 end) as orders_cnt2  -- 92  should be 46
--     ,sum(case when orders_cnts = 3 then 1 else 0 end) as orders_cnt3  -- 111  should be 37 - it's like the answer is multiplied by the cnt 3x37 = 111
--     ,count(orders_cnts) as orders_total                               -- 361 should be 136 
--     ,avg(orders_hour)::decimal(10,2) as avg_orders_hr                 -- 16.21
--     ,avg(delivery_time / 60)::decimal(10,2) as avg_delivery_time_hrs  -- 93.4 

-- from orders
