{% snapshot inventory_snapshot %}
-- see https://docs.getdbt.com/reference/snapshot-properties for info on the setup
{{
  config(
    target_database = target.database,  -- database that dbt should build a snapshot table into
    target_schema = target.schema,      -- schema that dbt should build a snapshot table into
    strategy='check',                   -- creates snapshot is any of the rows in check_cols have changed ('timestamp' compares to 'updated at')
                                        -- see https://docs.getdbt.com/docs/build/snapshots#check-strategy
    check_cols=['status'],              -- list of columns within the results of your snapshot query to check for changes

    unique_key='order_id',              -- 'order_id' is the primary key, but we could use anything provided it has unique values
   )
}}


  SELECT * FROM {{ source('postgres', 'orders') }}

{% endsnapshot %}