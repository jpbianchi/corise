{{
  config(
    materialized='table'
  )
}}

select * 

FROM {{ source('postgres', 'orders') }}