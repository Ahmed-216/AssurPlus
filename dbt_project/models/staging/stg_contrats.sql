{{
    config(
        materialized='view'
    )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'contrats') }}
),

typed AS (
    SELECT
        contrat_id::INTEGER AS contrat_id,
        lead_id::INTEGER AS lead_id,
        commercial_id::INTEGER AS commercial_id,
        date_signature::DATE AS date_signature,
        produit,
        prime_annuelle::NUMERIC AS prime_annuelle,
        statut
    FROM source
),

-- Get valid lead_ids and commercial_ids for filtering
valid_leads AS (
    SELECT DISTINCT lead_id::INTEGER AS lead_id
    FROM {{ source('raw', 'leads') }}
),

valid_commerciaux AS (
    SELECT DISTINCT id::INTEGER AS commercial_id
    FROM {{ source('raw', 'commerciaux') }}
    WHERE id IS NOT NULL AND id != ''
),

-- Get first call date per lead to check temporal consistency
first_calls AS (
    SELECT
        lead_id::INTEGER AS lead_id,
        MIN(date_appel::TIMESTAMP) AS date_premier_appel
    FROM {{ source('raw', 'appels') }}
    GROUP BY lead_id::INTEGER
),

-- Filter out invalid contracts
cleaned AS (
    SELECT t.*
    FROM typed t
    INNER JOIN valid_leads vl ON t.lead_id = vl.lead_id
    INNER JOIN valid_commerciaux vc ON t.commercial_id = vc.commercial_id
    LEFT JOIN first_calls fc ON t.lead_id = fc.lead_id
    -- Keep contracts that either:
    -- 1. Have no calls (shouldn't happen but be defensive)
    -- 2. Were signed on or after the first call
    WHERE fc.lead_id IS NULL 
       OR t.date_signature >= fc.date_premier_appel::DATE
)

SELECT * FROM cleaned
