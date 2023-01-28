{{
  config(
    materialized='table'
  )
}}

/*
  I'm not going to do sthg elaborate here, just the page views / product / day
*/

select 
  date_trunc('day', created_at) as day
  , product_id_viewed
  , count(product_id_viewed) as nb_page_views_day


from {{ ref("core_fct_events") }}
where product_id_viewed is not null
group by 1, 2
order by 1
