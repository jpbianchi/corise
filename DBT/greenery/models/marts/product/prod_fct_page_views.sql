{{
  config(
    materialized='table'
  )
}}

/*
  I'm not going to do sthg elaborate here, just the page views / product / day
*/

select 
  date_trunc('day', e.created_at) as day
  ,product_id
  ,count(product_id) as nb_page_views_day


from {{ ref("stg_postgres_events") }} e
left join {{ ref("core_fct_orders") }} o
using (order_id)
where e.event_type = 'page_view'
group by 1, 2


