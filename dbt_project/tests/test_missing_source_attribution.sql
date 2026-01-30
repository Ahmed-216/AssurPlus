-- Test: Missing source attribution (Part 1.1.4)
-- This test identifies leads without acquisition source information

SELECT
    lead_id,
    prenom,
    nom,
    date_creation,
    source AS acquisition_source,
    commercial_assigne_id
FROM {{ source('raw', 'leads') }}
WHERE source IS NULL OR source = ''
