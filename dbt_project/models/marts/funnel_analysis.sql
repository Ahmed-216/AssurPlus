-- ======================================================================================
-- FUNNEL ANALYSIS: Analyser le parcours complet des leads de la création à la signature
-- ======================================================================================

WITH lead_first_call AS (
    -- Identifier le premier appel pour chaque lead
    SELECT 
        lead_id,
        MIN(date_appel) AS first_call_date,
        MIN(CASE WHEN statut = 'connected' THEN date_appel END) AS first_successful_call_date
    FROM {{ ref('appels') }}
    GROUP BY lead_id
),

lead_call_stats AS (
    -- Calculer les statistiques d'appels par lead
    SELECT 
        lead_id,
        COUNT(*) AS total_calls,
        SUM(CASE WHEN statut = 'connected' THEN 1 ELSE 0 END) AS successful_calls,
        SUM(CASE WHEN statut IN ('no_answer', 'messagerie', 'repondeur') THEN 1 ELSE 0 END) AS unsuccessful_calls
    FROM {{ ref('appels') }}
    GROUP BY lead_id
)
-- Construire le funnel complet pour chaque lead
SELECT 
    l.lead_id,
    l.date_creation,
    l.source,
    l.commercial_assigne_id,
    c.commercial_id AS commercial_contrat_id,
    
    -- Étape 1: Lead créé
    1 AS created,
    
    -- Étape 2: Lead contacté (au moins 1 appel tenté)
    CASE WHEN fc.lead_id IS NOT NULL THEN 1 ELSE 0 END AS contacted,
    
    -- Étape 3: Lead joint (au moins 1 appel connecté)
    CASE WHEN lcs.successful_calls > 0 THEN 1 ELSE 0 END AS reached,

    -- Étape 4: Lead contacté plusieurs fois
    CASE WHEN lcs.successful_calls >= 2 THEN 1 ELSE 0 END AS multiple_contacts,
    
    -- Étape 5: Lead converti (a signé un contrat)
    CASE WHEN c.lead_id IS NOT NULL THEN 1 ELSE 0 END AS converted

FROM {{ ref('leads') }} l
LEFT JOIN lead_first_call fc 
    ON l.lead_id = fc.lead_id
LEFT JOIN lead_call_stats lcs 
    ON l.lead_id = lcs.lead_id
LEFT JOIN {{ ref('contrats') }} c
    ON l.lead_id = c.lead_id
    AND c.statut = 'actif'
ORDER BY l.lead_id
