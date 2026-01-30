-- =============================================================================
-- ASSURPLUS CASE STUDY — SQL QUERIES
-- =============================================================================
-- These queries can be run directly against the Postgres database
-- after running: docker compose up postgres_db -d
-- Connect with: docker compose exec postgres_db psql -U assurplus -d assurplus
-- =============================================================================

-- =============================================================================
-- PART 1.1 — DATA QUALITY DIAGNOSTICS
-- =============================================================================

-- Query 1.1.1: Duplicate leads (same phone or email)
-- ---------------------------------------------------
WITH lead_duplicates_phone AS (
    SELECT
        telephone,
        COUNT(*) AS count_leads,
        STRING_AGG(lead_id::TEXT, ', ' ORDER BY lead_id) AS lead_ids
    FROM analytics.leads
    WHERE telephone IS NOT NULL
    GROUP BY telephone
    HAVING COUNT(*) > 1
),
lead_duplicates_email AS (
    SELECT
        email,
        COUNT(*) AS count_leads,
        STRING_AGG(lead_id::TEXT, ', ' ORDER BY lead_id) AS lead_ids
    FROM analytics.leads
    WHERE email IS NOT NULL
    GROUP BY email
    HAVING COUNT(*) > 1
)
SELECT 'Duplicate Phone' AS duplicate_type, telephone AS value, count_leads, lead_ids FROM lead_duplicates_phone
UNION ALL
SELECT 'Duplicate Email' AS duplicate_type, email AS value, count_leads, lead_ids FROM lead_duplicates_email;


-- Query 1.1.2: Orphan calls (lead_id not in leads table)
-- -------------------------------------------------------
SELECT
    a.appel_id,
    a.lead_id,
    a.commercial_id,
    a.date_appel,
    a.statut
FROM analytics.appels a
LEFT JOIN analytics.leads l ON a.lead_id = l.lead_id
WHERE l.lead_id IS NULL
ORDER BY a.date_appel;


-- Query 1.1.3: Temporal inconsistencies (contract signed before first call)
-- --------------------------------------------------------------------------
WITH premier_appel AS (
    SELECT
        lead_id,
        MIN(date_appel) AS date_premier_appel
    FROM analytics.appels
    GROUP BY lead_id
)
SELECT
    c.contrat_id,
    c.lead_id,
    c.date_signature,
    pa.date_premier_appel,
    c.date_signature - pa.date_premier_appel::DATE AS diff_jours
FROM analytics.contrats c
INNER JOIN premier_appel pa ON c.lead_id = pa.lead_id
WHERE c.date_signature < pa.date_premier_appel::DATE
ORDER BY c.date_signature;


-- Query 1.1.4: Other anomalies - Commercial mismatch
-- ---------------------------------------------------
WITH lead_primary_caller AS (
    SELECT
        lead_id,
        commercial_id,
        COUNT(*) AS call_count
    FROM analytics.appels
    GROUP BY lead_id, commercial_id
),
lead_most_active_caller AS (
    SELECT DISTINCT ON (lead_id)
        lead_id,
        commercial_id AS primary_caller_id,
        call_count
    FROM lead_primary_caller
    ORDER BY lead_id, call_count DESC
)
SELECT
    c.contrat_id,
    c.lead_id,
    c.commercial_id AS contract_commercial_id,
    lmc.primary_caller_id,
    lmc.call_count AS calls_by_primary,
    l.commercial_assigne_id AS assigned_commercial_id
FROM analytics.contrats c
INNER JOIN lead_most_active_caller lmc ON c.lead_id = lmc.lead_id
INNER JOIN analytics.leads l ON c.lead_id = l.lead_id
WHERE c.commercial_id != lmc.primary_caller_id
ORDER BY c.date_signature;


-- =============================================================================
-- PART 1.2 — PERFORMANCE ANALYSIS BY COMMERCIAL
-- =============================================================================

WITH appels_agg AS (
    SELECT
        commercial_id,
        COUNT(*) AS total_appels,
        COUNT(CASE WHEN statut = 'connected' THEN 1 END) AS appels_connectes,
        COUNT(DISTINCT lead_id) AS leads_distincts_contactes
    FROM analytics.appels
    GROUP BY commercial_id
),
contrats_agg AS (
    SELECT
        commercial_id,
        COUNT(*) AS nombre_contrats
    FROM analytics.contrats
    GROUP BY commercial_id
),
commerciaux AS (
    SELECT
        id AS commercial_id,
        nom,
        email
    FROM analytics.commerciaux
)
SELECT
    c.commercial_id,
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
FROM commerciaux c
LEFT JOIN appels_agg a ON c.commercial_id = a.commercial_id
LEFT JOIN contrats_agg ct ON c.commercial_id = ct.commercial_id
ORDER BY nombre_contrats DESC, taux_conversion_pct DESC;


-- =============================================================================
-- PART 1.3 — SALES CYCLE ANALYSIS (Leads with contracts)
-- =============================================================================

WITH premier_appel AS (
    SELECT
        lead_id,
        MIN(date_appel) AS date_premier_appel
    FROM analytics.appels
    GROUP BY lead_id
),
appels_par_lead AS (
    SELECT
        lead_id,
        COUNT(*) AS nombre_appels,
        MAX(date_appel) - MIN(date_appel) AS duree_totale_appels
    FROM analytics.appels
    GROUP BY lead_id
),
contrats_avec_stats AS (
    SELECT
        c.contrat_id,
        c.lead_id,
        c.date_signature,
        c.produit,
        c.prime_annuelle,
        pa.date_premier_appel,
        apl.nombre_appels,
        EXTRACT(DAY FROM c.date_signature - pa.date_premier_appel::DATE) AS jours_premier_appel_signature,
        CASE 
            WHEN apl.nombre_appels > 1 THEN 
                EXTRACT(EPOCH FROM apl.duree_totale_appels) / 86400.0 / (apl.nombre_appels - 1)
            ELSE NULL
        END AS delai_moyen_entre_appels_jours
    FROM analytics.contrats c
    INNER JOIN premier_appel pa ON c.lead_id = pa.lead_id
    INNER JOIN appels_par_lead apl ON c.lead_id = apl.lead_id
)
SELECT
    lead_id,
    contrat_id,
    date_signature,
    produit,
    prime_annuelle,
    nombre_appels AS nombre_appels_avant_signature,
    jours_premier_appel_signature AS delai_jours_premier_appel_signature,
    ROUND(delai_moyen_entre_appels_jours::NUMERIC, 2) AS delai_moyen_entre_appels_jours
FROM contrats_avec_stats
ORDER BY date_signature;


-- Summary statistics for sales cycle
SELECT
    ROUND(AVG(nombre_appels), 2) AS avg_appels_avant_signature,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY nombre_appels), 2) AS median_appels,
    MIN(nombre_appels) AS min_appels,
    MAX(nombre_appels) AS max_appels,
    ROUND(AVG(jours_premier_appel_signature), 2) AS avg_jours_conversion,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY jours_premier_appel_signature), 2) AS median_jours_conversion,
    MIN(jours_premier_appel_signature) AS min_jours_conversion,
    MAX(jours_premier_appel_signature) AS max_jours_conversion
FROM (
    SELECT
        c.lead_id,
        COUNT(a.appel_id) AS nombre_appels,
        EXTRACT(DAY FROM c.date_signature - MIN(a.date_appel)::DATE) AS jours_premier_appel_signature
    FROM analytics.contrats c
    INNER JOIN analytics.appels a ON c.lead_id = a.lead_id
    WHERE a.date_appel <= c.date_signature::TIMESTAMP
    GROUP BY c.lead_id, c.date_signature
) stats;
