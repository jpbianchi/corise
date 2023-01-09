{{
  config(
    materialized='table'
  )
}}

select * 

FROM {{ source('postgres', 'order_items') }}