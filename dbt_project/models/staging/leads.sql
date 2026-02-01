{{
    config(
        materialized='view'
    )
}}

WITH typed AS (
    SELECT
        lead_id::INTEGER AS lead_id,
        prenom,
        nom,
        telephone,
        email,
        date_creation::TIMESTAMP AS date_creation,
        source,
        CASE 
            WHEN commercial_assigne_id = '' THEN NULL
            ELSE commercial_assigne_id::INTEGER
        END AS commercial_assigne_id
    FROM {{ source('raw', 'leads') }}
    WHERE lead_id IS NOT NULL AND lead_id != ''
)

SELECT 
    t.lead_id,
    t.prenom,
    t.nom,
    t.telephone,
    t.email,
    t.date_creation,
    t.source,
    vc.commercial_id commercial_assigne_id
FROM typed t
LEFT JOIN {{ ref('commerciaux') }} vc 
    ON t.commercial_assigne_id = vc.commercial_id



