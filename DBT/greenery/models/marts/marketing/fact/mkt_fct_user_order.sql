{{
  config(
    materialized='table'
  )
}}

select 
  user_id
  ,first_name
  ,last_name
  ,order_id
  ,o.created_at
  ,order_cost
  ,order_total
  ,promo_description
  ,promo_discount
  ,promo_status
  ,zipcode
  ,country
  ,delivered_at  -- to estimate the influence of delivery time on repeat orders maybe?


from {{ ref("core_dim_users") }} u
join {{ ref("core_fct_orders") }} o
using (user_id)
