{{
  config(
    materialized='table'
  )
}}

select 
  order_id
  ,oi.product_id
  ,coalesce(pr.promo_id, 'NO PROMO') as promo_description
  ,pr.discount as promo_discount
  ,o.status as promo_status
  ,o.user_id
  ,o.created_at
  ,o.order_cost
  ,o.order_total
  ,o.shipping_cost
  ,o.tracking_id
  ,o.delivered_at
  ,o.status as delivery_status

from {{ ref("stg_postgres_orders") }} o
left join {{ ref("stg_postgres_order_items") }} oi
using(order_id)
left join {{ ref("stg_postgres_promos") }} pr
using(promo_id)
order by order_id
