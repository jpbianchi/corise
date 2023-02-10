-- I created a temporary function to avoid modifying the database 'public'
-- and I prob didn't have the privileges anyway
-- run the function below separately
-- then run the sql code separately

create or replace temporary function match_city_name (customer_city text, customer_state text,
                                                      state text, city_names array)
returns boolean
language python
runtime_version = '3.8'
handler = 'match'
as
$$
def match(customer_city, customer_state, state, city_names):
    if customer_state != state:
        return False

    return any(c.lower() in customer_city.lower() for c in city_names)
$$;


with active_customers as (  -- renamed s into active_customers
    select
        customer_id,
        count(*) as food_pref_count
    from vk_data.customers.customer_survey
    where is_active = true
    group by 1
)

, chic as (
    select
        geo_location
    from vk_data.resources.us_cities
    where trim(city_name) = 'CHICAGO' and trim(state_abbr) = 'IL'  -- better trim all cities, state names
)

, gary as (
    select
        geo_location
    from vk_data.resources.us_cities
    where trim(city_name) = 'GARY'
      and trim(state_abbr) = 'IN'
)

-- We can filter the cities before the join with user data, which will make it much quicker
, cities as (
    select
        trim(us_cities.state_abbr) as state_abbr
        , trim(us_cities.city_name) as city_name
        , us_cities.geo_location as geo_location

    from vk_data.resources.us_cities as us_cities -- missing 'as'

    where
          match_city_name(city_name, state_abbr, 'KY', array_construct('concord', 'georgetown', 'ashland'))
       or match_city_name(city_name, state_abbr, 'CA', array_construct('oakland', 'pleasant hill'))
       or match_city_name(city_name, state_abbr, 'TX', array_construct('arlington', 'brownsville'))
)

, output as (
    select first_name || ' ' || last_name as customer_name,
       initcap(trim(cust_addr.customer_city)) as customer_city,    -- trim names to be sure
       upper(trim(cust_addr.customer_state)) as customer_state,    -- trim names to be sure
       active_cust.food_pref_count,
       (st_distance(cities.geo_location, chic.geo_location) / 1609)::int as chicago_distance_miles,
       (st_distance(cities.geo_location, gary.geo_location) / 1609)::int as gary_distance_miles

    -- I kept the aliases because using full table names makes it all a blur
    -- but I made the aliases more meaningful so we know what we're joining on
    from vk_data.customers.customer_address as cust_addr
         inner join vk_data.customers.customer_data as cust_data -- missing 'as'
            on cust_addr.customer_id = cust_data.customer_id -- clearer with 'inner'

         inner join cities -- missing 'as'
                           -- changed left join into inner join because of I filtered the cities already
           on upper(trim(cust_addr.customer_state)) =
              upper(cities.state_abbr) -- all low caps, trim instead of rtrim(ltrim(
                and
              trim(lower(cust_addr.customer_city)) = trim(lower(cities.city_name))

         inner join active_customers as active_cust -- used meaningful CTE name but kept alias
              on cust_data.customer_id = active_cust.customer_id

         cross join chic -- turned the subquery into CTE

         cross join gary -- turned the subquery into CTE
)
select * from output;