{{
  config( materialized='table' )
}}


with events as (
    select * from {{ ref("core_fct_events") }}
)

-- ,orders as (
--     select * from {{ ref("core_fct_orders") }}
-- )

select 
    count(distinct e.order_id)/ count(distinct e.session_id) as conv_rate_global -- 0.624

from events e
-- inner join orders o using (order_id)    
-- where o.status == 'abc'
-- group by 1,2,3,4,5,6
-- limit 1000
