-- Test: Data type validation failures (Part 1.1.4)
-- This test identifies rows where expected numeric/date columns contain invalid values

SELECT 'leads' AS table_name, lead_id, 'lead_id not numeric' AS issue
FROM {{ source('raw', 'leads') }}
WHERE lead_id !~ '^[0-9]+$'

UNION ALL

SELECT 'appels' AS table_name, appel_id, 'duree_secondes not numeric' AS issue
FROM {{ source('raw', 'appels') }}
WHERE duree_secondes !~ '^[0-9]+$'

UNION ALL

SELECT 'contrats' AS table_name, contrat_id, 'prime_annuelle not numeric' AS issue
FROM {{ source('raw', 'contrats') }}
WHERE prime_annuelle !~ '^[0-9]+(\.[0-9]+)?$'
