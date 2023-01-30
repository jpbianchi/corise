{{
  config(
    materialized='table'
  )
}}

with orders as (
  select * from {{ ref("core_fct_orders") }}
)

, events as (
  select * from {{ ref("stg_postgres_events") }}
)

, products as (
  select * from {{ ref("core_dim_products") }}
)

/*
  I'm not going to do sthg elaborate here, just the daily orders / product
*/

select 
  date_trunc('day', o.created_at) as day
  , o.product_id
  ,count(o.product_id) as nb_prod_ordered_day


from {{ ref("core_fct_events") }} e
left join {{ ref("core_fct_orders") }} o
using (order_id)
where e.checkout_cnt > 0 
group by 1, 2
