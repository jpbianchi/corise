-- 1st part
with valid_customers as (
    select
          d.CUSTOMER_ID as id
        , d.EMAIL as email_address
        , initcap(trim(d.LAST_NAME)) as lastname
        , initcap(trim(d.FIRST_NAME)) as firstname
        , lastname || ' ' || firstname as full_name
        , initcap(lower(trim(a.CUSTOMER_CITY ))) as city  -- high cap first letter
        , upper(trim(a.CUSTOMER_STATE)) as state
--         , ST_MakePoint(ci.LONG, ci.LAT) as geolocation  -- for the record, if we didn't have the geolocation
        , ci.GEO_LOCATION as geolocation

    from
         vk_data.customers.customer_data d
         inner join vk_data.customers.customer_address a
         using (CUSTOMER_ID)
         inner join vk_data.resources.us_cities ci  -- inner join otherwise a left join could still take invalid customers
         on
           (trim(upper(a.CUSTOMER_CITY)) = trim(upper(ci.CITY_NAME)))
               and
           (upper(trim(a.CUSTOMER_STATE)) = upper(trim(ci.STATE_ABBR)))

    -- let's pick any of the multiple geolocations, all slightly different from each other
    -- I guess they were taken at delivery time by some sensor, so for sure never exactly identical
    qualify (row_number() over (partition by d.CUSTOMER_ID order by ci.LONG)) = 1
)
-- I included unit tests after CTE's; uncomment them and run the code,
-- then check the output with the expected output below, then recomment the test line

-- select * from valid_customers order by full_name limit 25;  -- <<< UNCOMMENT AND RUN TO TEST
-- LASTNAME,FIRSTNAME,FULL_NAME,CITY,STATE
-- Abreu,Else,Abreu Else,Riverview,MI
-- Ackley,Jennifer,Ackley Jennifer,Mount Olive,NC
-- Acosta,Tammy,Acosta Tammy,Kingston,AR
-- Acosta,Tony,Acosta Tony,Ashland,LA
-- Adair,Joseph,Adair Joseph,Spring Valley,CA
-- Adams,Annie,Adams Annie,Greenfield,IL

, suppliers as (
    -- let's get the geolocations of all suppliers
    -- I don't remove duplicates city/state (some has several counties)
    -- because it will be filtered out when we pick THE shortest distance
    select
          trim(su.SUPPLIER_NAME) as supplier
        , initcap(lower(trim(su.SUPPLIER_CITY))) as city
        , upper(trim(su.SUPPLIER_STATE)) as state
        , su.SUPPLIER_ID as supplier_id
        , ci.GEO_LOCATION as geolocation

    from
        vk_data.suppliers.supplier_info su
        left join vk_data.resources.us_cities ci
        on (initcap(lower(trim(su.SUPPLIER_CITY))) = initcap(lower(trim(ci.CITY_NAME))))
            and
           (upper(trim(su.SUPPLIER_STATE)) = upper(trim(ci.STATE_ABBR)))
)
-- select * from suppliers order by supplier limit 20;
-- SUPPLIER,CITY,STATE
-- Anderson Family Market,Salt Lake City,UT
-- Burlington Food Supply,Burlington,VT
-- California Sunshine Shop,Sacramento,CA
-- Georgia Grocery Company,Atlanta,GA
-- Lazlo and Company,Cincinnati,OH
-- Lone Star Groceries and Supply,Austin,TX
-- Orlando Express Grocers,Orlando,FL
-- Phoenix and Maricopa County Suppliers,Phoenix,AZ
-- Rocky Mountain Food Express,Denver,CO
-- West Side Market,Chicago,IL

, closest_supplier as (
    select
           cu.id                                                                 as id
         , cu.full_name
         , cu.email_address
         , su.supplier                                                           as closest_supplier
         , su.supplier_id
         , round(ST_Distance(cu.geolocation, su.geolocation) / 1609,1)           as distance_miles
    from
         valid_customers cu
         cross join suppliers su

    qualify (row_number() over (partition by id order by distance_miles asc)) = 1
    order by 2 asc
)
-- select * from closest_supplier limit 25;   -- <<<<< RUN THIS LINE TO GET ANSWER TO QUESTION 1  <<<<<<<<<
-- select count(*) from closest_supplier;  -- 2401
-- FULL_NAME,CLOSEST_SUPPLIER,DISTANCE_MILES
-- Abreu Else,Lazlo and Company,220.5
-- Ackley Jennifer,Georgia Grocery Company,375.4
-- Acosta Tammy,Lone Star Groceries and Supply,466.8
-- Acosta Tony,Lone Star Groceries and Supply,301.3
-- Adair Joseph,Phoenix and Maricopa County Suppliers,288.7

, customer_tags as (
    select
        *
    from
        (select
              id
            , cu.email_address
            , cu.firstname
            , lower(trim(ta.tag_property)) as food_pref  -- one per row, we'll have to pivot this to get 3 columns
            , row_number() over (partition by id order by food_pref asc) as food_pref_number  -- to select how many we want
              -- I am not using qualify () this time because I need the food_pref_numbers in the pivot command below

        from valid_customers cu
        -- again, no left joins but inner joins otherwise we'll pick customers without a survey
        inner join VK_DATA.CUSTOMERS.CUSTOMER_SURVEY su on cu.id = su.CUSTOMER_ID
        inner join VK_DATA.RESOURCES.RECIPE_TAGS ta on su.TAG_ID = ta.TAG_ID
        where su.IS_ACTIVE
        order by firstname)  food_preferences

    -- we need to put the food_prefs 1,2 and 3 into separate columns (null value if some don't exist)
    pivot( max(food_pref) for food_pref_number in (1,2,3))  -- the row numbers are very handy here
        as pivot_values (id, email_address, firstname, food_pref1, food_pref2 , food_pref3)
)
-- select * from customer_tags order by firstname limit 30;  -- output is correct so far
-- EMAIL_ADDRESS,FIRSTNAME,FOOD_PREF1,FOOD_PREF2,FOOD_PREF3
-- Aaron.Davis@email.com,Aaron,beef-liver,healthy-2,oven
-- Aaron.Dugan@email.com,Aaron,beijing,frozen-desserts,irish-st-patricks-day
-- Aaron.Lentz@email.com,Aaron,granola-and-porridge,south-african,
-- Adela,hidden-valley-ranch,malaysian,
-- Adeline,breakfast,burgers,desserts-fruit
-- Adrianna,black-bean-soup,duck-breasts,main-ingredient

, recipe_tags as (
    select
          RECIPE_ID
        , RECIPE_NAME
        , lower(trim(flat_tag_list.VALUE)) as recipe_tag

    from VK_DATA.CHEFS.RECIPE, table(flatten(tag_list)) as flat_tag_list
)
-- select * from recipe_tags where recipe_tag = 'beef-liver' order by RECIPE_NAME limit 20;
-- RECIPE_NAME,RECIPE_TAG
-- arancini sicilian style sicilian rice balls,beef-liver
-- bacon wrapped chicken livers,beef-liver
-- baked calf liver and onions with gravy,beef-liver
-- beef liver  onions curried,beef-liver

-- select * from recipe_tags limit 20;
-- RECIPE_NAME,RECIPE_TAG
-- arriba  baked winter squash mexican style,60-minutes-or-less
-- arriba  baked winter squash mexican style,time-to-make
-- arriba  baked winter squash mexican style,course
-- arriba  baked winter squash mexican style,main-ingredient
-- arriba  baked winter squash mexican style,cuisine

, customer_prefs as (

    select
          cu.id  -- necessary for the partition otherwise the 3 Aarons get aggregated
        , cu.email_address
        , cu.firstname
        , cu.food_pref1
        , cu.food_pref2
        , cu.food_pref3
        , re.RECIPE_NAME as recipe  -- we can get many recipes for one tag

    from customer_tags cu
    -- we're told that only food_pref1 must be used to find a meal
    inner join recipe_tags re on cu.food_pref1 = re.recipe_tag
    -- if several meals correspond to food_pref1, we take the first alphabetically
    qualify (row_number() over (partition by id order by food_pref1 asc)) = 1
    order by firstname
)
-- 2nd part
select * from customer_prefs order by firstname limit 20;  -- <<<<< RUN THIS LINE TO GET ANSWER TO QUESTION 2  <<<<<<<<<
-- select count(*) from customer_prefs;
-- FIRSTNAME,FOOD_PREF1,FOOD_PREF2,FOOD_PREF3,RECIPE
-- Aaron,beef-liver,healthy-2,oven,easy chicken liver and brandy pate
-- Aaron,granola-and-porridge,south-african,,hungry girl complete  utter oatmeal insanity
-- Aaron,beijing,frozen-desserts,irish-st-patricks-day,boiled peanuts in the shell
-- Adam,vegetarian,,,pear upside down gingerbread cake
-- Adela,hidden-valley-ranch,malaysian,,crunchy chicken ranch panini rsc
-- Adeline,breakfast,burgers,desserts-fruit,peachy licious oatmeal

