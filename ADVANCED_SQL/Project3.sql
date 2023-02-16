-- we want, per day:
-- total unique sessions
-- the average length of sessions in seconds  (if only one event -> zero)
-- the average number of searches completed before displaying a recipe
-- the ID of the recipe that was most viewed
--
-- explain  -- returns statistics about the query - works in Datagrip
--
with real_activity as (
    select
        *

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

    -- mode() spreads the value to all rows in the partition, so we'll have
    -- to pick only one row using qualify
    , mode(rec.value) over (partition by event_day) as most_viewed_recipe

from averages, table(flatten(viewed_recipes)) as rec
qualify row_number() over (partition by event_day order by rec.value) = 1

order by event_day;

/*
QUERY PROFILE ANALYSIS:
From the query profile, we can see that 47% of the time was spent on finding the min and max EVENT_TIMESTAMP
for the session times.
The successive window function takes ~ 0%: that's probably because they operate on the same partition,
ordered in the same way, so I guess Snowflake saw that and reused the partition.

The join with the RECIPE table to transform the recipe_ids into recipe names is unavoidable, and takes 23%,
so I should have done it in the end, when we have the most viewed recipes and a smaller table.
I will fix that for next time, when we have a much bigger table to process.

The 3rd most expensive query is the sorting by the date, so, for the same reason, I did it in the end.

CODE STRUCTURE:
I started by removing the duplicate events to decrease the size of the table right off the bat.
Also, in the CTE's, I collapse the partition results using 'qualify' rather than
passing row_numbers to the next query which then does 'where row = 1',
in order to avoid passing a lot of data that will be discarded.
Although, I guess a good compiler could do that on its own, not sure.

Finally, I did all the partition calculations in one CTE, in order to allow Snowflake to re-use
the same partition.  We saw above that the first window function took 47% of the time,
and the next one almost zero, so I guess it was a good design choice, over creating
several CTE's for clarity (although, again, not sure how smart their compiler is).

*/
