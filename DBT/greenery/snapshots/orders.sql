{% snapshot orders_snapshot %}
{# see https://docs.getdbt.com/reference/snapshot-properties for info on the setup
   see https://docs.getdbt.com/docs/build/snapshots#check-strategy
#}

{{
  config(
    target_database = target.database,  
    target_schema = target.schema,      
    strategy='check',                   
                                        
    check_cols=['status'],              

    unique_key='order_id',              
   )
}}


  SELECT * FROM {{ source('postgres', 'orders') }}

{% endsnapshot %}