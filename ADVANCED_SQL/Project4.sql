with urgent_orders as (
    select
          C_CUSTKEY    as custkey
        , O_ORDERKEY   as orderkey
        , O_TOTALPRICE as totalprice
        , max(O_ORDERDATE) over (partition by C_CUSTKEY)  as last_order_date

        -- let's create a partition with the costliest orders first
        , row_number() over (partition by C_CUSTKEY order by O_TOTALPRICE desc) as biggest_orders_nb

        -- I calculate the cum sums and qualify will cut it at the 3rd order or before, then
        -- we take the max later - I did it to avoid writing a CTE to do just this
        , sum(O_TOTALPRICE) over (partition by C_CUSTKEY order by O_TOTALPRICE desc
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as total_expense

        , array_slice(array_agg (O_ORDERKEY) within group ( order by O_TOTALPRICE desc )
            over (partition by C_CUSTKEY),0,3) as orders

    from snowflake_sample_data.tpch_sf1.orders o
    left join snowflake_sample_data.tpch_sf1.customer as c on o.o_custkey = c.c_custkey
    where O_ORDERPRIORITY ilike '%urgent' and c.C_MKTSEGMENT ilike '%AUTOMOBILE%'
    qualify biggest_orders_nb <= 3  -- we want the first 3 biggest orders

)
-- select * from urgent_orders order by last_order_date desc, totalprice desc limit 20; -- test query

, parts_prices as (
    select
          uo.custkey         as custkey
        , it.L_PARTKEY       as partkey
        , sum(it.L_QUANTITY) as part_qtty
        , sum(it.L_EXTENDEDPRICE) as total_part_price
        , row_number() over (partition by custkey order by total_part_price desc) as rownb
    from urgent_orders uo
    left join snowflake_sample_data.tpch_sf1.lineitem it on uo.orderkey = it.L_ORDERKEY
    group by 1,2
    qualify rownb <= 3
    order by custkey, rownb
)
-- select * from parts_prices where custkey = 147580 order by total_part_price desc limit 20;

, top3parts as (
    select
          custkey
        , max(case when rownb = 1 then partkey end) as part_1_key
        , max(case when rownb = 1 then part_qtty end) as part_1_quantity
        , max(case when rownb = 1 then total_part_price end) as part_1_total_spent
        , max(case when rownb = 2 then partkey end) as part_2_key
        , max(case when rownb = 2 then part_qtty end) as part_2_quantity
        , max(case when rownb = 2 then total_part_price end) as part_2_total_spent
        , max(case when rownb = 3 then partkey end) as part_3_key
        , max(case when rownb = 3 then part_qtty end) as part_3_quantity
        , max(case when rownb = 3 then total_part_price end) as part_3_total_spent

    from parts_prices
    group by custkey  -- to merge the values of rows 1,2 and 3
)
-- select * from top3parts where custkey = 2 limit 20; --where custkey = 147580 limit 20;

, final as (
    select
         custkey
        , uo.last_order_date
        , array_to_string(uo.orders, ',') as order_numbers  -- to get a list separated by a comma
        , uo.total_expense as total_spent  -- the where clause will select the max value
        , t3.part_1_key, t3.part_1_quantity, t3.part_1_total_spent
        , t3.part_2_key, t3.part_2_quantity, t3.part_2_total_spent
        , t3.part_3_key, t3.part_3_quantity, t3.part_3_total_spent

    from urgent_orders uo
    left join top3parts t3 using (custkey)
    -- to get the proper 'total_spent', we need to take the row with
    -- the max biggest_orders_nb.  The easiest way is to simply
    -- use the nb of orders in the orders array
    where uo.biggest_orders_nb = array_size(uo.orders)
)
select *
from final
order by last_order_date desc, custkey desc
limit 100;



