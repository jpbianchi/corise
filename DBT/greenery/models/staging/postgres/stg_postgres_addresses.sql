{{
  config(
    materialized='table')
}}

select * 

FROM {{ source('postgres', 'addresses') }}
{# FROM {{ source('postgres', 'addresses') }}  #}