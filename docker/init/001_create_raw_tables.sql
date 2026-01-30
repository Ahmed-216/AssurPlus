CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS marts;

DROP TABLE IF EXISTS raw.leads;
DROP TABLE IF EXISTS raw.appels;
DROP TABLE IF EXISTS raw.contrats;
DROP TABLE IF EXISTS raw.commerciaux;

CREATE TABLE raw.leads (
  lead_id TEXT,
  prenom TEXT,
  nom TEXT,
  telephone TEXT,
  email TEXT,
  date_creation TEXT,
  source TEXT,
  commercial_assigne_id TEXT
);

CREATE TABLE raw.appels (
  appel_id TEXT,
  lead_id TEXT,
  commercial_id TEXT,
  commercial_email TEXT,
  date_appel TEXT,
  duree_secondes TEXT,
  statut TEXT,
  campagne_id TEXT,
  campagne_nom TEXT
);

CREATE TABLE raw.commerciaux (
  id TEXT,
  email TEXT,
  nom TEXT
);

CREATE TABLE raw.contrats (
  contrat_id TEXT,
  lead_id TEXT,
  commercial_id TEXT,
  date_signature TEXT,
  produit TEXT,
  prime_annuelle TEXT,
  statut TEXT
);
