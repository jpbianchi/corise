-- I am not using this macro
-- I copied it from another student to study it 
-- His code comes from https://docs.getdbt.com/docs/get-started/learning-more/using-jinja#dynamically-retrieve-the-list-of-payment-methods

{% macro unique_event_types() %} -- create macro

{% set event_query %}  -- set distinct query
select distinct
event_type
from stg_postgres__events
{% endset %}

{% set results = run_query(event_query) %} -- convenient way to run query and fetch the query above results

-- assign results to result list if query executes
-- and returns first column event_type in event_query
{% if execute %}
{% set results_list = results.columns[0].values() %}
{% else %}
{% set results_list = [] %}
{% endif %}

{{ return(results_list) }} -- return first column

{% endmacro %}