{{
    config(
        materialized='view'
    )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'appels') }}
),

typed AS (
    SELECT
        appel_id::INTEGER AS appel_id,
        lead_id::INTEGER AS lead_id,
        commercial_id::INTEGER AS commercial_id,
        commercial_email,
        date_appel::TIMESTAMP AS date_appel,
        duree_secondes::INTEGER AS duree_secondes,
        statut,
        campagne_id::INTEGER AS campagne_id,
        campagne_nom
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

-- Filter out orphan calls (invalid lead_id or commercial_id)
cleaned AS (
    SELECT t.*
    FROM typed t
    INNER JOIN valid_leads vl ON t.lead_id = vl.lead_id
    INNER JOIN valid_commerciaux vc ON t.commercial_id = vc.commercial_id
)

SELECT * FROM cleaned
