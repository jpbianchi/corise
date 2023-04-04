{{
  config(materialized='table')
}}

{% set event_types = dbt_utils.get_column_values(table=ref('core_fct_events_funnel'), column='event_type') %}

with events as (
    select *
    from {{ ref('core_fct_events_funnel') }}
)

, order_products as (
    select *
    from {{ ref("prod_fct_orders") }}
)
, session_dates as (
    select 
      session_id
      , min(created_at) as session_started_ts_utc
      , max(created_at) as session_ended_ts_utc
    from events
    group by 1
)

, user_product_sessions as (
    select 
        e.session_id
        , e.user_id
        , coalesce(e.product_id, op.product_id) as product_id
      {% for event_type in event_types %}
        , {{ unique_counts(column_name="e.event_type", 
                          column_value=event_type, 
                          value_counted='e.event_id', 
                          new_name=event_type) }}
      {% endfor %}
    from events e
    left join order_products op
        on op.order_id = e.order_id
    group by 1, 2, 3
)

select
    s.session_id
    , s.user_id
    , s.product_id
    , d.session_started_ts_utc
    , d.session_ended_ts_utc
    , s.page_view
    , s.add_to_cart
    , s.checkout
    , s.package_shipped
from user_product_sessions s
left join session_dates d on
    d.session_id = s.session_id
