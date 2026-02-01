{{
    config(
        materialized='table',
    )
}}

WITH appels_stats AS (
    SELECT
        lead_id,
        MIN(date_appel::TIMESTAMP) AS date_premier_appel,
        MIN(CASE WHEN statut = 'connected' THEN date_appel::TIMESTAMP END) AS date_premier_appel_connecte,
        COUNT(*) AS nombre_appels,
        MAX(date_appel::TIMESTAMP) - MIN(date_appel::TIMESTAMP) AS intervalle_appels
    FROM {{ ref('appels') }}
    GROUP BY lead_id
)
SELECT
    c.lead_id,
    c.contrat_id,
    l.prenom,
    l.nom,
    c.produit,
    a.nombre_appels AS nombre_appels_avant_signature,
    a.date_premier_appel,
    a.date_premier_appel_connecte,
    c.date_signature,
    c.date_signature::DATE - a.date_premier_appel::DATE AS delai_premier_appel_signature,
    CASE 
        WHEN a.nombre_appels > 1 THEN 
            ROUND((c.date_signature::DATE - a.date_premier_appel::DATE)::NUMERIC / (a.nombre_appels - 1), 2)
        ELSE NULL
    END AS delai_moyen_entre_appels
FROM {{ ref('contrats') }} c
JOIN appels_stats a 
    ON c.lead_id = a.lead_id
JOIN {{ ref('leads') }} l 
    ON c.lead_id = l.lead_id
WHERE c.statut != 'annule'  -- Only analyze successful conversions
ORDER BY c.lead_id 
