{{
    config(
        materialized='table'
    )
}}

SELECT
    id::INTEGER AS commercial_id,
    email,
    nom
FROM {{ source('raw', 'commerciaux') }}
WHERE id IS NOT NULL AND id != ''


