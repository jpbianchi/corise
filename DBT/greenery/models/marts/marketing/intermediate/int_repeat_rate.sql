{{
  config(
    materialized='table')
}}

/*
    Calculates the quantity and percentage of users having placed 2+ orders
*/

select 
    sum((orders_cnts > 1)::int) as cnts2ormore              -- 99
    ,sum((orders_cnts > 0)::int) as total_orders            -- 124
    ,div0(cnts2ormore, total_orders) as two_Or_More_Pct     -- 0.798

from (
    select 
        user_id
        ,count(distinct order_id) as orders_cnts

    from {{ ref('core_fct_orders') }}
    group by user_id
)
