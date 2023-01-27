{{
  config(
    materialized='table'
  )
}}

/*
  I'm not going to do sthg elaborate here, just the daily orders / product
*/

select 
  date_trunc('day', e.created_at) as day
  ,product_id
  ,count(product_id) as nb_prod_ordered_day


from {{ ref("stg_postgres_events") }} e
left join {{ ref("core_fct_orders") }} o
using (order_id)
where e.event_type = 'add_to_cart'
group by 1, 2
