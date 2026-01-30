-- Test: Suspicious call durations (Part 1.1.4)
-- This test identifies calls with unusual durations that may indicate data quality issues

SELECT
    appel_id,
    lead_id,
    commercial_id,
    date_appel,
    duree_secondes::INTEGER AS duree_secondes,
    statut,
    CASE
        WHEN statut = 'connected' AND duree_secondes::INTEGER < 30 THEN 'Too short for meaningful conversation'
        WHEN statut != 'connected' AND duree_secondes::INTEGER > 60 THEN 'Long duration for non-connected call'
        WHEN duree_secondes::INTEGER > 3600 THEN 'Unusually long call (>1 hour)'
    END AS anomaly_reason
FROM {{ source('raw', 'appels') }}
WHERE
    (statut = 'connected' AND duree_secondes::INTEGER < 30)
    OR (statut != 'connected' AND duree_secondes::INTEGER > 60)
    OR duree_secondes::INTEGER > 3600
