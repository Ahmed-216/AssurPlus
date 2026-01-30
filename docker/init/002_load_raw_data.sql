COPY raw.leads (lead_id, prenom, nom, telephone, email, date_creation, source, commercial_assigne_id)
FROM '/data/leads.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';');

COPY raw.appels (appel_id, lead_id, commercial_id, commercial_email, date_appel, duree_secondes, statut, campagne_id, campagne_nom)
FROM '/data/appels.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';');

COPY raw.commerciaux (id, email, nom)
FROM '/data/commerciaux.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';');

COPY raw.contrats (contrat_id, lead_id, commercial_id, date_signature, produit, prime_annuelle, statut)
FROM '/data/contrats.csv'
WITH (FORMAT csv, HEADER true, DELIMITER ';');
