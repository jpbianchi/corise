{{
  config( materialized='table' )
}}

{% set event_table = 'stg_postgres_events' %}

{% set event_types = dbt_utils.get_column_values(table=ref(event_table), column='event_type')%} 
   -- https://github.com/dbt-labs/dbt-utils/tree/1.0.0/#get_column_values-source
   -- get_column_values gives the UNIQUE values in a column



with events as (
    select * from {{ ref(event_table) }} 
)

,orders as (
    select * from {{ ref("stg_postgres_orders") }}
)

,products as (
    select * from {{ ref("core_dim_products") }}
)

,useful_events as (
    -- we eliminate event_id which are irrelevant since there is one
    -- for every single thing, ie per product visited, purchased etc
    -- so we're going to group by session_id and aggregate what can be 
    -- aggregated and useful
    -- if one looks at the table, he can see that there are many 
    -- event_ids for each session (because everything that a
    -- user does during the session creates a new event_id)

    select
        session_id
        , user_id
        , order_id
        , e.created_at
        , case when e.event_type = 'page_view' then product_id end as product_id_viewed 
        -- null for orders !! join with order_items using order_id to get the ordered items

        , min(created_at::timestamp) as first_session_utc
        , max(created_at::timestamp) as last_session_utc

        -- let's count the nb of each event type for every session
        {%- for event_type in event_types %}
        , {{ unique_counts(column_name="e.event_type", column_value=event_type, value_counted='e.event_id', new_name=event_type ~ "_cnt") }}
        {%- endfor %}

    from events e
    {{ dbt_utils.group_by(5) }}
)

select * from useful_events