{{
  config(
    materialized='table'
  )
}}

{# use role transformer_dev
use warehouse transformer_dev_wh#}

select * 

FROM {{ source('postgres', 'events') }}