-- Test: Invalid commercial references (Part 1.1.4)
-- This test identifies calls, contracts, or leads referencing non-existent commerciaux

SELECT 'appels' AS table_name, appel_id AS record_id, commercial_id
FROM {{ source('raw', 'appels') }} a
WHERE NOT EXISTS (
    SELECT 1 FROM {{ source('raw', 'commerciaux') }} c WHERE c.id = a.commercial_id
)
UNION ALL
SELECT 'contrats' AS table_name, contrat_id AS record_id, commercial_id
FROM {{ source('raw', 'contrats') }} ct
WHERE NOT EXISTS (
    SELECT 1 FROM {{ source('raw', 'commerciaux') }} c WHERE c.id = ct.commercial_id
)
UNION ALL
SELECT 'leads' AS table_name, lead_id AS record_id, commercial_assigne_id AS commercial_id
FROM {{ source('raw', 'leads') }} l
WHERE commercial_assigne_id IS NOT NULL 
  AND commercial_assigne_id != ''
  AND NOT EXISTS (
    SELECT 1 FROM {{ source('raw', 'commerciaux') }} c WHERE c.id = l.commercial_assigne_id
)
