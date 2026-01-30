# Test Technique — Analytics Engineer (Skarlett)

***AssurPlus (entreprise fictive)***

| **Durée** | **2h** |
| --- | --- |
| Fichiers fournis | leads.csv, appels.csv, contrats.csv, commerciaux.csv |
| Livrables | Fichier SQL + Document avec réponses (PDF, Notion, Google Doc) |

## Contexte

AssurPlus est un courtier en assurance pour seniors (60+). L'équipe commerciale de 8 personnes passe des appels pour convertir des leads en contrats. Tu as accès à un extrait de données couvrant janvier 2026.

**Attention :** les données contiennent volontairement des anomalies. Leur détection fait partie du test.

## Structure des données

### leads.csv

| **Colonne** | **Description** |
| --- | --- |
| lead_id | Identifiant unique |
| prenom, nom | Identité du lead |
| telephone, email | Coordonnées |
| date_creation | Date d'entrée dans le CRM |
| source | Canal d'acquisition |
| commercial_assigne_id | Commercial assigné au lead |

### appels.csv

| **Colonne** | **Description** |
| --- | --- |
| appel_id | Identifiant unique |
| lead_id | Lead appelé |
| commercial_id, commercial_email | Commercial ayant passé l'appel |
| date_appel | Date et heure de l'appel |
| duree_secondes | Durée de l'appel en secondes |
| statut | connected, no_answer, busy, messagerie, faux_numero, repondeur |
| campagne_id, campagne_nom | Campagne d'appel |

### commerciaux.csv

| **Colonne** | **Description** |
| --- | --- |
| id | Identifiant unique |
| email | Email professionnel |
| nom | Nom complet du commercial |

### contrats.csv

| **Colonne** | **Description** |
| --- | --- |
| contrat_id | Identifiant unique |
| lead_id | Lead ayant signé |
| commercial_id | Commercial ayant signé le contrat |
| date_signature | Date de signature |
| produit | Type de contrat souscrit |
| prime_annuelle | Montant annuel en euros |
| statut | actif, annule, en_attente |

## Partie 1 — Diagnostic & SQL (45 min)

### 1.1 — Qualité des données

Écris les requêtes SQL pour identifier :

- Les leads en doublon (même téléphone ou même email)
- Les appels orphelins (lead_id qui n'existe pas dans la table leads)
- Les incohérences temporelles (contrat signé avant le premier appel au lead)
- Toute autre anomalie que tu détectes dans les données

### 1.2 — Analyse de performance

Écris une requête qui calcule, par commercial, pour la période :

- Nombre total d'appels passés
- Taux de joignabilité (appels connectés / total appels)
- Nombre de contrats signés
- Taux de conversion (contrats / leads distincts contactés)

### 1.3 — Analyse du cycle de vente

Écris une requête qui calcule, pour chaque lead ayant signé un contrat :

- Le nombre d'appels avant la signature
- Le délai (en jours) entre le premier appel et la signature
- Le délai moyen entre chaque appel (pour les leads ayant reçu 2+ appels)

## Partie 2 — Modélisation (30 min)

### 2.1 — Modèle de données

Le CEO veut un dashboard pour piloter la performance commerciale. Propose un schéma de données optimisé pour l'analytics.

*Questions à adresser :*

- Comment structurerais-tu les données pour éviter les requêtes lentes ?
- Quelles métriques pré-calculerais-tu ?
- Comment gérerais-tu l'historique (un lead peut changer de statut) ?

Tu peux dessiner un schéma ou décrire en texte.

### 2.2 — Tests de qualité

Si tu utilisais dbt (ou un outil équivalent), quels tests mettrais-tu en place pour garantir la fiabilité des données ?

Liste 5 tests essentiels avec une phrase d'explication pour chacun.

## Partie 3 — Cas pratique (45 min)

Le directeur commercial te dit :

*« J'ai l'impression qu'on perd beaucoup de leads entre le premier appel et la signature. Je voudrais comprendre où ça coince. »*

### 3.1 — Approche

Décris comment tu aborderais cette demande :

- Quelles questions poserais-tu pour clarifier le besoin ?
- Quelles analyses ferais-tu ?
- Quelles données te manquent potentiellement ?

### 3.2 — Dashboard

Esquisse un dashboard qui répondrait à cette problématique. Précise :

- Les 4-5 KPIs clés que tu afficherais
- Les filtres utiles
- Une visualisation qui permettrait d'identifier « où ça coince »

### 3.3 — Limites et biais

En analysant les données fournies, identifies-tu des biais ou des limites qui pourraient fausser ton analyse du funnel de conversion ?

Comment les adresserais-tu avant de présenter tes conclusions au directeur commercial ?

---

**Bonne chance !** 🚀
