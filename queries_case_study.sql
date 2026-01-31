-- =============================================================================
-- ASSURPLUS CASE STUDY — SQL QUERIES
-- =============================================================================

-- =============================================================================
-- PARTIE 1.1 — Qualité des données
-- =============================================================================

-- Requête 1.1.1 : Leads en doublon (même téléphone ou email)
-- ---------------------------------------------------
WITH lead_duplicates_phone AS (
    SELECT
        telephone,
        COUNT(*) AS count_leads,
        STRING_AGG(lead_id, ', ' ORDER BY lead_id) AS lead_ids
    FROM raw.leads
    WHERE telephone IS NOT NULL AND telephone != ''
    GROUP BY telephone
    HAVING COUNT(*) > 1
),
lead_duplicates_email AS (
    SELECT
        email,
        COUNT(*) AS count_leads,
        STRING_AGG(lead_id, ', ' ORDER BY lead_id) AS lead_ids
    FROM raw.leads
    WHERE email IS NOT NULL AND email != ''
    GROUP BY email
    HAVING COUNT(*) > 1
)
SELECT 
    'Duplicate Phone' AS duplicate_type, 
    telephone AS value, 
    count_leads, 
    lead_ids 
FROM lead_duplicates_phone
UNION ALL
SELECT 
    'Duplicate Email' AS duplicate_type, 
    email AS value, 
    count_leads, 
    lead_ids 
FROM lead_duplicates_email;


-- Requête 1.1.2 : Appels orphelins (lead_id n'existe pas dans la table leads)
-- -------------------------------------------------------
SELECT
    a.appel_id,
    a.lead_id,
    a.commercial_id,
    a.date_appel,
    a.statut
FROM raw.appels a
LEFT JOIN raw.leads l 
    ON a.lead_id = l.lead_id
WHERE l.lead_id IS NULL
ORDER BY a.date_appel::TIMESTAMP;


-- Requête 1.1.3 : Incohérences temporelles (contrat signé avant le premier appel)
-- --------------------------------------------------------------------------
WITH premier_appel AS (
    SELECT
        lead_id,
        MIN(date_appel::TIMESTAMP) AS date_premier_appel
    FROM raw.appels
    GROUP BY lead_id
)
SELECT
    c.contrat_id,
    c.lead_id,
    c.date_signature::DATE AS date_signature,
    pa.date_premier_appel::DATE AS date_premier_appel
FROM raw.contrats c
JOIN premier_appel pa 
    ON c.lead_id = pa.lead_id
WHERE c.date_signature::DATE < pa.date_premier_appel::DATE;

-- Requête 1.1.4 : Autres anomalies 
-- ---------------------------------------------------

-- Adresses email incohérentes

SELECT 
    a.appel_id,
    a.commercial_id,
    a.commercial_email AS commercial_email_from_appels,
    c.email AS commercial_email_from_commerciaux
FROM raw.appels a
LEFT JOIN raw.commerciaux c 
    ON a.commercial_id = c.id
WHERE a.commercial_email IS NOT NULL AND a.commercial_email != ''
  AND a.commercial_email != c.email;

-- Incohérence de commercial assigné : le commercial du contrat n'est pas celui qui a effectué le plus d'appels

WITH lead_callers AS (
    SELECT
        lead_id,
        commercial_id,
        COUNT(*) AS call_count
    FROM raw.appels
    WHERE statut = 'connected'
    GROUP BY lead_id, commercial_id
),
lead_primary_caller AS (
    SELECT DISTINCT ON (lead_id)
        lead_id,
        commercial_id AS primary_caller_id,
        call_count
    FROM lead_callers
    ORDER BY lead_id, call_count DESC
)
SELECT
    c.contrat_id,
    c.lead_id,
    l.commercial_assigne_id AS assigned_commercial_id,
    c.commercial_id AS contract_commercial_id,
    lpc.primary_caller_commercial_id,
    lpc.call_count AS connected_calls_by_primary_commercial,
    COALESCE(lc.call_count, 0) AS connected_calls_by_contract_commercial
FROM raw.contrats c
JOIN lead_primary_caller lpc 
    ON c.lead_id = lpc.lead_id
JOIN raw.leads l 
    ON c.lead_id = l.lead_id
LEFT JOIN lead_callers lc 
    ON c.commercial_id = lc.commercial_id
    AND c.lead_id = lc.lead_id
WHERE (lc.call_count IS NULL AND c.commercial_id != lpc.primary_caller_id) OR lpc.call_count != lc.call_count;

-- Note : Les autres tests de qualité des données sont appliqués avec dbt


-- =============================================================================
-- PARTIE 1.2 — ANALYSE DE PERFORMANCE
-- =============================================================================

WITH appels_agg AS (
    SELECT
        a.commercial_id,
        COUNT(*) AS total_appels,
        COUNT(CASE WHEN statut = 'connected' THEN 1 END) AS appels_connectes,
        COUNT(DISTINCT lead_id) AS leads_distincts_contactes
    FROM raw.appels a
    JOIN raw.commerciaux c
        ON a.commercial_id = c.id
    GROUP BY commercial_id
),
contrats_agg AS (
    SELECT
        commercial_id,
        COUNT(*) AS nombre_contrats
    FROM raw.contrats c
    JOIN raw.commerciaux com
        ON c.commercial_id = com.id
    WHERE statut != 'annule'  -- Exclude canceled contracts from conversion metrics
    GROUP BY commercial_id
)
SELECT
    c.id as commercial_id,
    c.nom,
    COALESCE(a.total_appels, 0) AS total_appels,
    COALESCE(a.appels_connectes, 0) AS appels_connectes,
    CASE 
        WHEN COALESCE(a.total_appels, 0) = 0 THEN 0
        ELSE ROUND(100.0 * a.appels_connectes / a.total_appels, 2)
    END AS taux_joignabilite_pct,
    COALESCE(ct.nombre_contrats, 0) AS nombre_contrats,
    COALESCE(a.leads_distincts_contactes, 0) AS leads_distincts_contactes,
    CASE 
        WHEN COALESCE(a.leads_distincts_contactes, 0) = 0 THEN 0
        ELSE ROUND(100.0 * ct.nombre_contrats / a.leads_distincts_contactes, 2)
    END AS taux_conversion_pct
FROM raw.commerciaux c
LEFT JOIN appels_agg a 
    ON c.id = a.commercial_id
LEFT JOIN contrats_agg ct 
    ON c.id = ct.commercial_id
ORDER BY nombre_contrats DESC, taux_conversion_pct DESC;


-- =============================================================================
-- PARTIE 1.3 — ANALYSE DU CYCLE DE VENTE (Leads ayant signé un contrat)
-- =============================================================================

WITH appels_stats AS (
    SELECT
        lead_id,
        MIN(date_appel::TIMESTAMP) AS date_premier_appel,
        COUNT(*) AS nombre_appels,
        MAX(date_appel::TIMESTAMP) - MIN(date_appel::TIMESTAMP) AS intervalle_appels
    FROM raw.appels
    GROUP BY lead_id
)
SELECT
    c.lead_id,
    l.prenom,
    l.nom,
    c.contrat_id,
    c.produit,
    a.nombre_appels AS nombre_appels_avant_signature,
    c.date_signature::DATE - a.date_premier_appel::DATE AS delai_jours_premier_appel_signature,
    CASE 
        WHEN a.nombre_appels > 1 THEN 
            ROUND((c.date_signature::DATE - a.date_premier_appel::DATE) / (a.nombre_appels - 1), 2)
        ELSE NULL
    END AS delai_moyen_entre_appels_jours
FROM raw.contrats c
JOIN appels_stats a 
    ON c.lead_id = a.lead_id
JOIN raw.leads l 
    ON c.lead_id = l.lead_id
WHERE c.statut != 'annule'  -- Only analyze successful conversions
  AND c.date_signature::DATE >= a.date_premier_appel::DATE  -- Exclude contracts signed before first call
ORDER BY c.date_signature;



