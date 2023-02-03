{{
  config(materialized='view')
}}


with successes as (
select 
    distinct session_id
    , max(checkout) over (partition by session_id) as successful_order

from {{ ref('prod_fct_funnel') }}
)

select 
    sum(successful_order) / count(session_id) as conv_rate  -- 0.6246
from successes


