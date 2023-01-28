{{
  config(
    materialized='table'
  )
}}


select 
  product_id
  ,pi.name       as product_name
  ,price      as product_price
  ,inventory  as produt_inventory
  ,coalesce(promo_id, 'NO PROMO') as promo_description 

from {{ ref("stg_postgres_products") }} pi
join {{ ref("stg_postgres_order_items")}} oi
using (product_id)
left join {{ ref("stg_postgres_orders")}}
using(order_id)
order by product_id