-- we want, per day:
-- total unique sessions
-- the average length of sessions in seconds  (if only one event -> zero)
-- the average number of searches completed before displaying a recipe
-- the ID of the recipe that was most viewed
--
-- explain  -- returns statistics about the query - works in Datagrip
-- alter session set use_cached_result = false -- disable cached results

with real_activity1 as (
    -- let's remove duplicate entries
    -- group by is faster than distinct

    select
        EVENT_TIMESTAMP
        , SESSION_ID
        , EVENT_DETAILS
        , true as is_not_a_duplicate_event  -- for code compatibility

    from VK_DATA.EVENTS.WEBSITE_ACTIVITY
    group by 1,2,3
)

, real_activity as (
    -- removing the duplicates this way is MUCH faster than with group by
    select
        EVENT_TIMESTAMP
        , SESSION_ID
        , EVENT_DETAILS

        -- with event data, some events can occur twice, so we need to flag the repeats
        -- before we start counting the nb of searches
        , EVENT_ID != lag(EVENT_ID, 1, '123') over (partition by session_id order by EVENT_ID) as is_not_a_duplicate_event

    from VK_DATA.EVENTS.WEBSITE_ACTIVITY
)

, daily_values as (
    select
        EVENT_TIMESTAMP::date as event_day
        , EVENT_TIMESTAMP
        , session_id

         -- EVENT_DETAILS is varchar, not json, so we must parse it
        , parse_json(EVENT_DETAILS) as events  -- flatten() creates one row per key, this doesn't

        , datediff('sec', min(EVENT_TIMESTAMP) over (partition by session_id),
            max(EVENT_TIMESTAMP) over (partition by session_id)) as session_length

        -- this will increment every time a recipe is viewed (we'll take the first)
        , conditional_true_event((events:event='view_recipe') and (events:recipe_id is not null))
            over (partition by session_id order by EVENT_TIMESTAMP) as recipe_views

        -- this increments every time we get a search event inside the session partition
        -- so we just have to take the value where recipe_views = 1
        -- to know how many searches occurred before the first recipe view
        , conditional_true_event((events:event='search') and (events:page='search'))
            over (partition by session_id order by EVENT_TIMESTAMP) as search_rows

        -- here, we put all the recipes viewed during a session in a string
        -- I didn't use an array because we will aggregate them in the next query
        -- and I didn't find a nice way to parse an array of arrays
        , listagg(rec.RECIPE_NAME,'|~|') within group ( order by EVENT_TIMESTAMP )
            over (partition by session_id) as recipes_session

    from real_activity a
    left join VK_DATA.CHEFS.RECIPE rec on parse_json(a.EVENT_DETAILS):recipe_id = rec.RECIPE_ID
    where is_not_a_duplicate_event
    qualify recipe_views = 1  -- we take the first viewed recipe
            and session_length > 0  -- drop the sessions with only 1 event
)
-- select * from daily_values order by event_day, session_id, EVENT_TIMESTAMP limit 20;  -- uncomment for testing

, averages as (
    select event_day
         -- we can count the unique sessions without passing session_id to save memory
         , count(*)                      as sessions_day -- nb of rows = nb of unique sessions
         , avg(session_length)           as avg_session_length
         , avg(search_rows)              as avg_searches_before_recipe_view

         -- let's aggregate all the recipes in a big string, then convert it to an array
         -- that we will convert into a column and use mode() to find the most frequent value
         , STRTOK_TO_ARRAY(listagg(recipes_session,'|~|'),'|~|') as viewed_recipes

    from daily_values
    group by event_day
)
-- select * from averages order by event_day limit 20;

select
    event_day, sessions_day, avg_session_length, avg_searches_before_recipe_view

    , mode(rec.value) over (partition by event_day) as most_viewed_recipe

from averages, table(flatten(viewed_recipes)) as rec
qualify row_number() over (partition by event_day order by rec.value) = 1

order by event_day;

