-- Test: Temporal inconsistencies - contracts signed before first call (Part 1.1.3)
-- This test fails if any contract was signed before the first call to that lead

WITH premier_appel AS (
    SELECT
        lead_id,
        MIN(date_appel::TIMESTAMP) AS date_premier_appel
    FROM {{ source('raw', 'appels') }}
    GROUP BY lead_id
)

SELECT
    c.contrat_id,
    c.lead_id,
    c.date_signature,
    pa.date_premier_appel,
    c.date_signature::DATE - pa.date_premier_appel::DATE AS diff_jours
FROM {{ source('raw', 'contrats') }} c
INNER JOIN premier_appel pa ON c.lead_id = pa.lead_id
WHERE c.date_signature::DATE < pa.date_premier_appel::DATE
