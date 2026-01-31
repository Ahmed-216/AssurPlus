{{
    config(
        materialized='table'
    )
}}

WITH typed AS (
    SELECT
        appel_id::INTEGER,
        lead_id::INTEGER,
        commercial_id::INTEGER,
        date_appel::TIMESTAMP,
        CASE 
            WHEN duree_secondes::INTEGER < 0 THEN NULL
            ELSE duree_secondes::INTEGER
        END AS duree_secondes, -- Negative call durations are set to NULL
        statut,
        campagne_id::INTEGER,
        campagne_nom
    FROM {{ source('raw', 'appels') }}
)
SELECT 
    t.appel_id,
    vl.lead_id, -- Invalid lead_id references are set to NULL
    vc.commercial_id, -- Invalid commercial_id references are set to NULL
    t.date_appel,
    t.duree_secondes,
    t.statut,
    t.campagne_id,
    t.campagne_nom
FROM typed t
LEFT JOIN {{ ref('stg_leads') }} vl 
    ON t.lead_id = vl.lead_id
LEFT JOIN {{ ref('stg_commerciaux') }} vc 
    ON t.commercial_id = vc.commercial_id

