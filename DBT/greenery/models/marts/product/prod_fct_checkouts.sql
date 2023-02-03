{{
  config(
    materialized='table'
  )
}}

with orders as (
  select * from {{ ref("core_fct_orders") }}
)

, events as (
  select * from {{ ref("core_fct_events") }}
)


select 
  date_trunc('day', e.created_at) as day
  , e.session_id

from events e
left join orders o
using (order_id)

where e.checkout_cnt > 0 
group by 1, 2