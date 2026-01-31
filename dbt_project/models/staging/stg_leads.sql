{{
    config(
        materialized='view'
    )
}}

WITH typed AS (
    SELECT
        lead_id::INTEGER AS lead_id,
        prenom,
        nom,
        telephone,
        email,
        date_creation::TIMESTAMP AS date_creation,
        source AS acquisition_source,
        CASE 
            WHEN commercial_assigne_id = '' THEN NULL
            ELSE commercial_assigne_id::INTEGER
        END AS commercial_assigne_id
    FROM {{ source('raw', 'leads') }}
    WHERE lead_id IS NOT NULL AND lead_id != ''
),

-- Filter out invalid commercial_assigne_id references
valid_commerciaux AS (
    SELECT DISTINCT id::INTEGER AS commercial_id
    FROM {{ source('raw', 'commerciaux') }}
),

cleaned AS (
    SELECT 
        t.*
    FROM typed t
    LEFT JOIN valid_commerciaux vc 
        ON t.commercial_assigne_id = vc.commercial_id
    WHERE t.commercial_assigne_id IS NULL 
       OR vc.commercial_id IS NOT NULL
)

SELECT * FROM cleaned
