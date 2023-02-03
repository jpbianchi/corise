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

/*
  I'm not going to do sthg elaborate here, just the daily orders / product / order
*/

select 
  date_trunc('day', o.created_at) as day
  , order_id
  , o.product_id
  , count(o.product_id) as nb_prod_ordered_day


from events e
left join orders o
using (order_id)
-- where e.checkout_cnt > 0 -- removed so it works with pro_fct_funnel, but then the merge is useless
group by 1, 2, 3
