{{
    config(
        materialized='view'
    )
}}

WITH source AS (
    SELECT * FROM {{ source('raw', 'leads') }}
),

typed AS (
    SELECT
        lead_id::INTEGER AS lead_id,
        prenom,
        nom,
        telephone,
        email,
        date_creation::TIMESTAMP AS date_creation,
        source AS acquisition_source,
        CASE 
            WHEN commercial_assigne_id = '' THEN NULL
            ELSE commercial_assigne_id::INTEGER
        END AS commercial_assigne_id
    FROM source
),

-- Deduplicate by telephone: keep earliest lead by date_creation
dedupe_phone AS (
    SELECT DISTINCT ON (telephone)
        lead_id,
        prenom,
        nom,
        telephone,
        email,
        date_creation,
        acquisition_source,
        commercial_assigne_id
    FROM typed
    WHERE telephone IS NOT NULL AND telephone != ''
    ORDER BY telephone, date_creation ASC, lead_id ASC
),

-- Deduplicate by email: keep earliest lead by date_creation
dedupe_email AS (
    SELECT DISTINCT ON (email)
        lead_id,
        prenom,
        nom,
        telephone,
        email,
        date_creation,
        acquisition_source,
        commercial_assigne_id
    FROM typed
    WHERE email IS NOT NULL AND email != ''
    ORDER BY email, date_creation ASC, lead_id ASC
),

-- Union of deduped records + those with no phone/email
all_unique_leads AS (
    -- Leads with unique phone (earliest by date)
    SELECT * FROM dedupe_phone
    
    UNION
    
    -- Leads with unique email (earliest by date) that weren't already selected by phone
    SELECT de.*
    FROM dedupe_email de
    WHERE NOT EXISTS (
        SELECT 1 FROM dedupe_phone dp WHERE dp.lead_id = de.lead_id
    )
    
    UNION
    
    -- Leads with no phone and no email (shouldn't happen but handle it)
    SELECT t.*
    FROM typed t
    WHERE (t.telephone IS NULL OR t.telephone = '')
      AND (t.email IS NULL OR t.email = '')
)

SELECT * FROM all_unique_leads
