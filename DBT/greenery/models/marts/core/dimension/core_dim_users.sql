{{
  config(
    materialized='table'
  )
}}

select 
  user_id
  ,first_name
  ,last_name
  ,email
  ,phone_number
  ,created_at
  ,address
  ,zipcode
  ,state
  ,country

from {{ ref("stg_postgres_users") }}
left join {{ ref("stg_postgres_addresses") }}
using (address_id)
order by last_name