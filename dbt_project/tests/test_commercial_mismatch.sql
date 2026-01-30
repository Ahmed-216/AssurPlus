-- Test: Commercial mismatch - contracts assigned to different commercial than primary caller (Part 1.1.4)
-- This test identifies contracts where the assigned commercial differs from who called the lead most

WITH lead_primary_caller AS (
    SELECT
        lead_id,
        commercial_id,
        COUNT(*) AS call_count
    FROM {{ source('raw', 'appels') }}
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
    lmc.call_count AS calls_by_primary
FROM {{ source('raw', 'contrats') }} c
INNER JOIN lead_most_active_caller lmc ON c.lead_id = lmc.lead_id
WHERE c.commercial_id != lmc.primary_caller_id
