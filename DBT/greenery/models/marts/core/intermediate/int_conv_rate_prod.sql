{{
  config( materialized='table' )
}}


with events as (
    select * from {{ ref("core_fct_events") }}  
)

,orders as (
    select * from {{ ref("core_fct_orders") }}
)

,products as (
    select * from {{ ref("core_dim_products") }}
)

,conversion_rate as (
select 
    nvl(o.product_id, e.product_id_viewed) as product_id  
    -- product_id in events is for page views only, so we need product_id from oder_items to 
    -- count purchases but we need the product id from events because those are linked to page_views
    -- but we joined on order_id, so we need nvl to coalesce both

    , p.product_name as product_name

    , {{ unique_counts(column_name="e.order_id", new_name="orders_cnt") }} 
    , {{ unique_counts(column_name="e.session_id", new_name="page_views") }}
    -- I created core_fct_events with product_id_viewed which already tests for event_type = 'page views'
    -- and we group by it, so we just need to count the session_ids

    , div0(orders_cnt, page_views) as conv_rate_prod

from events e
full join orders o using (order_id)  -- maybe some products were viewed but never purchased
full join products p on (o.product_id = p.product_id or e.product_id_viewed = p.product_id)
{{ dbt_utils.group_by(2) }}  -- for group by 1,2
)

select 
    product_id
    , product_name
    , conv_rate_prod

from conversion_rate
-- where conv_rate_prod > 0  -- useless since we joined on order_id
order by conv_rate_prod desc -- most successful products first
-- limit 20


