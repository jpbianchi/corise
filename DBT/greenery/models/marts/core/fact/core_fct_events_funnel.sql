{{
  config( materialized='table' )
}}


with events as (
    select * from {{ ref('stg_postgres_events') }} 
)
 -- I created this model for the product funnel but
 -- it's just info straight from stg_postgrest_events

,useful_events as (


    select
        session_id
        , event_id
        , user_id
        , order_id
        , event_type
        , created_at
        , product_id -- null for orders !! exists only for page views
        -- join with order_items using order_id to get the ordered items

    from events e
)

select * from useful_events