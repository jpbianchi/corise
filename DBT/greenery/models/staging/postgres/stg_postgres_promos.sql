{{
  config(
    materialized='table'
  )
}}

select * 

FROM {{ source('postgres', 'promos') }}