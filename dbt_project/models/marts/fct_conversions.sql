{{
    config(
        materialized='table',
        description='Conversion funnel analysis for leads with contracts'
    )
}}

WITH premier_appel AS (
    SELECT
        lead_id,
        MIN(date_appel) AS date_premier_appel,
        MIN(appel_id) AS premier_appel_id
    FROM {{ ref('stg_appels') }}
    GROUP BY lead_id
),

stats_appels AS (
    SELECT
        a.lead_id,
        COUNT(*) AS nombre_appels,
        COUNT(CASE WHEN a.statut = 'connected' THEN 1 END) AS appels_connectes,
        SUM(a.duree_secondes) AS duree_totale_secondes,
        pa.date_premier_appel
    FROM {{ ref('stg_appels') }} a
    INNER JOIN premier_appel pa ON a.lead_id = pa.lead_id
    GROUP BY a.lead_id, pa.date_premier_appel
),

contrats AS (
    SELECT
        lead_id,
        contrat_id,
        commercial_id,
        date_signature,
        produit,
        prime_annuelle,
        statut
    FROM {{ ref('stg_contrats') }}
    WHERE statut != 'annule'  -- Only analyze successful conversions
),

leads AS (
    SELECT
        lead_id,
        prenom,
        nom,
        acquisition_source,
        date_creation,
        commercial_assigne_id
    FROM {{ ref('stg_leads') }}
)

SELECT
    l.lead_id,
    l.prenom,
    l.nom,
    l.acquisition_source,
    l.date_creation,
    sa.date_premier_appel,
    c.date_signature,
    c.contrat_id,
    c.produit,
    c.prime_annuelle,
    c.statut AS statut_contrat,
    sa.nombre_appels AS nombre_appels_avant_signature,
    sa.appels_connectes,
    sa.duree_totale_secondes,
    EXTRACT(DAY FROM c.date_signature - sa.date_premier_appel::DATE) AS jours_premier_appel_signature,
    CASE 
        WHEN sa.nombre_appels > 1 THEN 
            EXTRACT(DAY FROM c.date_signature - sa.date_premier_appel::DATE) / (sa.nombre_appels - 1.0)
        ELSE NULL
    END AS delai_moyen_entre_appels_jours,
    c.commercial_id
FROM contrats c
INNER JOIN leads l ON c.lead_id = l.lead_id
INNER JOIN stats_appels sa ON c.lead_id = sa.lead_id
ORDER BY c.date_signature DESC
