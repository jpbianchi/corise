
{%- macro unique_counts(column_name, new_name, column_value=None, value_counted=none) %}

  {%- if target.name == "dev" %}  -- not necessary, just to learn how to use it

        {%- if column_value is none %}
            count(distinct {{column_name}}) as {{new_name}}  -- count doesn't count NULLs
        {%- else %}
            count(distinct case when {{column_name}} = '{{column_value}}' then {{value_counted}} else NULL end) as {{new_name}}
            -- we put column_value between quotes because here, we need a string to compare column_name with
            -- e.g. case when e.event_type = 'page view', otherwise we would get ... = page view... which won't work
        {%- endif %} 

  {%- else %}
        {%- if column_value is none %}
            count(distinct {{column_name}}) as {{new_name}}  -- count doesn't count NULLs
        {%- else %}
            count(distinct case when {{column_name}} = '{{column_value}}' then {{value_counted}} else NULL end) as {{new_name}}
        {%- endif %} 

  {%- endif %}

{%- endmacro %}
