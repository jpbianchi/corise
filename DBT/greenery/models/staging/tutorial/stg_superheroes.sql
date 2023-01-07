{{
  config(
    materialized='table'
  )
}}  -- without this config block, it's a view

SELECT 
    id AS superhero_id,
    name,
    gender,
    eye_color,
    race,
    hair_color,
    height,  -- NULLIF(height, -99) AS height, -- to pass test
    publisher,
    skin_color,
    alignment,
    weight,  -- NULLIF(weight, -99) AS weight
    {{ lbs_to_kgs('weight') }} AS weight_kg  -- macro lbs_to_kgs.sol
FROM {{ source('tutorial', 'superheroes') }}