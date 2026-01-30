WITH source AS (
    SELECT * FROM {{ source('raw', 'commerciaux') }}
),

cleaned AS (
    SELECT
        id::INTEGER AS commercial_id,
        email,
        nom
    FROM source
    WHERE id IS NOT NULL AND id != ''
)

SELECT * FROM cleaned
