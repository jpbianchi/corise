{{
  config(
    materialized='table'
  )
}}

with users as (
    select 
    -- I have to do this here because dbt_utils.star doesn't work with CTEs
    {{ dbt_utils.star(ref("stg_postgres_users"), except=["updated_at"]) }}
    
    from {{ ref("stg_postgres_users") }} 
)

,addresses as (
    select * from {{ ref("stg_postgres_addresses") }}
)

select 
 *
  -- address_id  -- I couldn't remove it since I needed it for the join
  -- , user_id
  -- , first_name
  -- , last_name
  -- , email
  -- , phone_number
  -- , created_at
  -- , address
  -- , zipcode
  -- , state
  -- , country

from users
left join addresses using (address_id)
order by last_name