{{
    config(
        materialized='table'
    )
}}

WITH typed AS (
    SELECT
        contrat_id::INTEGER AS contrat_id,
        lead_id::INTEGER AS lead_id,
        commercial_id::INTEGER AS commercial_id,
        date_signature::DATE AS date_signature,
        produit,
        prime_annuelle::NUMERIC AS prime_annuelle,
        statut
    FROM {{ source('raw', 'contrats') }}
),

-- Get first call date per lead to check temporal consistency
first_calls AS (
    SELECT
        lead_id::INTEGER AS lead_id,
        MIN(date_appel::TIMESTAMP) AS date_premier_appel
    FROM {{ source('raw', 'appels') }}
    GROUP BY lead_id::INTEGER
),

SELECT 
    t.contrat_id,
    vl.lead_id, -- Invalid lead_id references are set to NULL
    vc.commercial_id, -- Invalid commercial_id references are set to NULL
    t.date_signature,
    t.produit,
    t.prime_annuelle,
    t.statut
FROM typed t
LEFT JOIN {{ ref('stg_leads') }} vl 
    ON t.lead_id = vl.lead_id
LEFT JOIN {{ ref('stg_commerciaux') }} vc 
    ON t.commercial_id = vc.commercial_id
LEFT JOIN first_calls fc 
    ON t.lead_id = fc.lead_id
-- Filter out contacts with inconsistent dates 
WHERE t.date_signature >= fc.date_premier_appel::DATE


