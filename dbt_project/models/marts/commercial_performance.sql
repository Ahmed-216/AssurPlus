{{
    config(
        materialized='table',
        description='Commercial performance metrics by sales rep'
    )
}}

WITH appels_agg AS (
    SELECT
        commercial_id,
        COUNT(*) AS total_appels,
        COUNT(CASE WHEN statut = 'connected' THEN 1 END) AS appels_connectes,
        COUNT(DISTINCT lead_id) AS leads_distincts_contactes,
        SUM(duree_secondes) AS duree_totale_secondes,
        AVG(CASE WHEN statut = 'connected' THEN duree_secondes END) AS duree_moy_connectes
    FROM {{ ref('stg_appels') }}
    GROUP BY commercial_id
),

contrats_agg AS (
    SELECT
        commercial_id,
        COUNT(*) AS nombre_contrats,
        COUNT(CASE WHEN statut = 'actif' THEN 1 END) AS contrats_actifs,
        COUNT(CASE WHEN statut = 'annule' THEN 1 END) AS contrats_annules,
        SUM(prime_annuelle) AS ca_total,
        SUM(CASE WHEN statut = 'actif' THEN prime_annuelle ELSE 0 END) AS ca_actif,
        AVG(prime_annuelle) AS prime_moyenne
    FROM {{ ref('stg_contrats') }}
    WHERE statut != 'annule'  -- Exclude canceled contracts from conversion metrics
    GROUP BY commercial_id
)

SELECT
    c.commercial_id,
    c.nom,
    c.email,
    COALESCE(a.total_appels, 0) AS total_appels,
    COALESCE(a.appels_connectes, 0) AS appels_connectes,
    CASE 
        WHEN COALESCE(a.total_appels, 0) = 0 THEN 0
        ELSE ROUND(100.0 * a.appels_connectes / a.total_appels, 2)
    END AS taux_joignabilite_pct,
    COALESCE(a.leads_distincts_contactes, 0) AS leads_distincts_contactes,
    COALESCE(ct.nombre_contrats, 0) AS nombre_contrats,
    COALESCE(ct.contrats_actifs, 0) AS contrats_actifs,
    COALESCE(ct.contrats_annules, 0) AS contrats_annules,
    CASE 
        WHEN COALESCE(a.leads_distincts_contactes, 0) = 0 THEN 0
        ELSE ROUND(100.0 * ct.nombre_contrats / a.leads_distincts_contactes, 2)
    END AS taux_conversion_pct,
    COALESCE(ct.ca_total, 0) AS ca_total,
    COALESCE(ct.ca_actif, 0) AS ca_actif,
    COALESCE(ct.prime_moyenne, 0) AS prime_moyenne,
    COALESCE(a.duree_totale_secondes, 0) AS duree_totale_secondes,
    COALESCE(a.duree_moy_connectes, 0) AS duree_moy_connectes_secondes
FROM {{ ref('stg_commerciaux') }} c
LEFT JOIN appels_agg a 
    ON c.commercial_id = a.commercial_id
LEFT JOIN contrats_agg ct 
    ON c.commercial_id = ct.commercial_id
ORDER BY nombre_contrats DESC, taux_conversion_pct DESC
