{{
  config(
    materialized='table'
  )
}}

/*
  I'm not going to do sthg elaborate here, just the page views / product / day
*/

with events as (
  select * from {{ ref("core_fct_events") }}
)

select 
  date_trunc('day', created_at) as day
  , session_id
  , product_id_viewed
  , count(product_id_viewed) as nb_page_views_day


from events
where product_id_viewed is not null
group by 1, 2, 3
order by 1
