-- Test: Data type validation failures 
-- This test identifies rows where expected numeric/date columns contain invalid values

-- Numeric validations
SELECT 'leads' AS table_name, lead_id AS record_id, 'lead_id not numeric' AS issue
FROM {{ source('raw', 'leads') }}
WHERE lead_id IS NOT NULL AND lead_id != '' AND lead_id !~ '^[0-9]+$'

UNION ALL

SELECT 'leads' AS table_name, lead_id AS record_id, 'commercial_assigne_id not numeric' AS issue
FROM {{ source('raw', 'leads') }}
WHERE commercial_assigne_id IS NOT NULL 
  AND commercial_assigne_id != '' 
  AND commercial_assigne_id !~ '^[0-9]+$'

UNION ALL

SELECT 'appels' AS table_name, appel_id AS record_id, 'appel_id not numeric' AS issue
FROM {{ source('raw', 'appels') }}
WHERE appel_id IS NOT NULL AND appel_id != '' AND appel_id !~ '^[0-9]+$'

UNION ALL

SELECT 'appels' AS table_name, appel_id AS record_id, 'lead_id not numeric' AS issue
FROM {{ source('raw', 'appels') }}
WHERE lead_id IS NOT NULL AND lead_id != '' AND lead_id !~ '^[0-9]+$'

UNION ALL

SELECT 'appels' AS table_name, appel_id AS record_id, 'commercial_id not numeric' AS issue
FROM {{ source('raw', 'appels') }}
WHERE commercial_id IS NOT NULL AND commercial_id != '' AND commercial_id !~ '^[0-9]+$'

UNION ALL

SELECT 'appels' AS table_name, appel_id AS record_id, 'duree_secondes not numeric' AS issue
FROM {{ source('raw', 'appels') }}
WHERE duree_secondes IS NOT NULL AND duree_secondes != '' AND duree_secondes !~ '^[0-9]+$'

UNION ALL

SELECT 'appels' AS table_name, appel_id AS record_id, 'campagne_id not numeric' AS issue
FROM {{ source('raw', 'appels') }}
WHERE campagne_id IS NOT NULL AND campagne_id != '' AND campagne_id !~ '^[0-9]+$'

UNION ALL

SELECT 'contrats' AS table_name, contrat_id AS record_id, 'contrat_id not numeric' AS issue
FROM {{ source('raw', 'contrats') }}
WHERE contrat_id IS NOT NULL AND contrat_id != '' AND contrat_id !~ '^[0-9]+$'

UNION ALL

SELECT 'contrats' AS table_name, contrat_id AS record_id, 'lead_id not numeric' AS issue
FROM {{ source('raw', 'contrats') }}
WHERE lead_id IS NOT NULL AND lead_id != '' AND lead_id !~ '^[0-9]+$'

UNION ALL

SELECT 'contrats' AS table_name, contrat_id AS record_id, 'commercial_id not numeric' AS issue
FROM {{ source('raw', 'contrats') }}
WHERE commercial_id IS NOT NULL AND commercial_id != '' AND commercial_id !~ '^[0-9]+$'

UNION ALL

SELECT 'contrats' AS table_name, contrat_id AS record_id, 'prime_annuelle not numeric' AS issue
FROM {{ source('raw', 'contrats') }}
WHERE prime_annuelle IS NOT NULL AND prime_annuelle != '' AND prime_annuelle !~ '^-?[0-9]+(\.[0-9]+)?$'

UNION ALL

SELECT 'commerciaux' AS table_name, id AS record_id, 'id not numeric' AS issue
FROM {{ source('raw', 'commerciaux') }}
WHERE id IS NOT NULL AND id != '' AND id !~ '^[0-9]+$'

-- Date validations
UNION ALL

SELECT 'leads' AS table_name, lead_id AS record_id, 'date_creation invalid format' AS issue
FROM {{ source('raw', 'leads') }}
WHERE date_creation IS NOT NULL 
  AND date_creation != ''
  AND date_creation::TIMESTAMP IS NULL

UNION ALL

SELECT 'appels' AS table_name, appel_id AS record_id, 'date_appel invalid format' AS issue
FROM {{ source('raw', 'appels') }}
WHERE date_appel IS NOT NULL 
  AND date_appel != ''
  AND date_appel::TIMESTAMP IS NULL

UNION ALL

SELECT 'contrats' AS table_name, contrat_id AS record_id, 'date_signature invalid format' AS issue
FROM {{ source('raw', 'contrats') }}
WHERE date_signature IS NOT NULL 
  AND date_signature != ''
  AND date_signature::DATE IS NULL
