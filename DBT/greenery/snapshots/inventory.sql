{% snapshot inventory_snapshot %}

  {{
    config(
      target_schema='snapshots',
      unique_key='id',
      enabled = false,
      strategy='timestamp',
      updated_at='updated_at',
    )
  }}


      -- strategy='check',
      -- check_cols=['status'],

  SELECT * FROM {{ source('mysql', 'inventory') }}

{% endsnapshot %}