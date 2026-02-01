# AssurPlus - Analytics Engineer Case Study

## Overview

This repository contains a complete analytics engineering solution for AssurPlus, including:

- **Raw data** (CSV files in `raw_data/`)
- **Postgres database** (Docker-based, auto-loads CSVs)
- **dbt project** (data modeling, transformations, quality tests)
- **Metabase** (BI tool for dashboards and visualizations)

## Quick Start

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and started
- Terminal access

### Build and start containers

Build the dbt Docker image:
```bash
docker compose build dbt
```

Start containers (Postgres + dbt):
```bash
docker compose up -d
```

This will:
- Start Postgres on `localhost:5432`
- Auto-load CSVs from `raw_data/` into `raw.*` tables
- Start dbt container (waits for Postgres to be healthy)

**With Metabase (optional, adds ~500MB download):**
```bash
docker compose --profile metabase up -d
```
This also starts Metabase on `localhost:3000` for dashboards and visualizations.

### Stop everything

```bash
docker compose down
```  


##  Run dbt (transformations + tests)

Install dbt packages (first time only):
```bash
docker compose exec dbt dbt deps
```

Run dbt models:
```bash
docker compose exec dbt dbt run
```

Run data quality tests:
```bash
docker compose exec dbt dbt test
```

Generate documentation:
```bash
docker compose exec dbt dbt docs generate
docker compose exec dbt dbt docs serve --host 0.0.0.0 --port 8080
```

## Data Structure

### Raw Tables (loaded from CSVs)

Located in `raw.*` schema :

- **`raw.leads`** — Lead data from CRM
- **`raw.appels`** — Call history
- **`raw.contrats`** — Signed contracts
- **`raw.commerciaux`** — Sales team roster


### dbt Models

#### Staging Models (`staging.*`)
Clean, typed, deduplicated foundation for all analytics:
- **`leads`** — Cleaned leads, typed, invalid commercial references filtered
- **`appels`** — Cleaned calls, typed, invalid foreign keys set to NULL
- **`contrats`** — Cleaned contracts, typed, temporal inconsistencies filtered
- **`commerciaux`** — Clean sales rep data

#### Mart Models (`marts.*`)
- **`commercial_performance`** — Commercial performance metrics (Part 1.2)
  - Total calls, connection rate, conversion rate per sales rep
- **`contrats_stat`** — Sales cycle analysis (Part 1.3)
  - Number of calls before signature, time to conversion, delays

## Data Quality Tests

The dbt project includes comprehensive tests:

1. **Uniqueness tests** — Primary keys (lead_id, appel_id, contrat_id, commercial_id)
2. **Not-null tests** — Required fields
3. **Referential integrity** — Foreign key relationships (using `relationships` test)
4. **Value constraints** — Accepted values for statuses, regex for emails/phones
5. **Range checks** — Using `dbt_expectations` for date ranges, numeric ranges
6. **Custom tests** — SQL-based tests for complex business rules (temporal inconsistencies, commercial mismatches, suspicious durations, etc.) 

Run all tests:
```bash
docker compose run --rm dbt dbt test
```

Run specific model tests:
```bash
docker compose exec dbt dbt test --select leads
```  

Run tests on source data:
```bash
docker compose exec dbt dbt test --select source:raw
```


## Access Metabase (BI Dashboard)

> **Note:** Start Metabase with `docker compose --profile metabase up -d`

Metabase will be available at: **http://localhost:3000**

### Pre-configured Setup 

This repository includes pre-configured Metabase dashboards in `metabase_data/`. When you start Metabase, the database connection and dashboards are already set up.

**Login credentials:**
- **Email**: admin
- **Password**: admin

4. Your configuration will be saved in `metabase_data/` and can be committed to Git

**Important:** Run `dbt run` before using Metabase to ensure all tables are created.



