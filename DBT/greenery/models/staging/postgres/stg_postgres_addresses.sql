{{
  config(
    materialized='table')
}}

select * 

FROM {{ source('stg_postgres', 'addresses') }}
{# FROM {{ source('postgres', 'addresses') }}  #}