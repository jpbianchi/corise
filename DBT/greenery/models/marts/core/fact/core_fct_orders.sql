{{
  config(
    materialized='table'
  )
}}

select 
  order_id
  ,product_id
  ,coalesce(promo_id, 'NO PROMO') as promo_description
  ,discount as promo_discount
  ,o.status as promo_status
  ,user_id
  ,created_at
  ,order_cost
  ,order_total
  ,shipping_cost
  ,tracking_id
  ,delivered_at
  ,pr.status as delivery_status

from {{ ref("stg_postgres_orders") }} o
left join {{ ref("stg_postgres_order_items") }}
using(order_id)
left join {{ ref("stg_postgres_promos") }} pr
using(promo_id)
order by order_id
