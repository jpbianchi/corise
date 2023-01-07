{{
  config(
    materialized='table'
  )
}}

{# use role transformer_dev
use warehouse transformer_dev_wh #}

select * 

FROM {{ source('postgres', 'events') }}
limit 20

-- code from the video https://www.loom.com/share/21e174c34ed64932b8a39ee42cd0aa59 at 2'35"
{# use role transformer_dev
use warehouse transformer_dev_wh

select * from raw public events
limit 20

select * from raw information_schema columns
where table_name = ORDERS

order by ordinal_position asc #}

