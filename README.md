# AssurPlus - Analytics Engineer Case Study

## Overview

This repository contains a complete analytics engineering solution for AssurPlus, including:

- **Raw data** (CSV files in `raw_data/`)
- **Postgres database** (Docker-based, auto-loads CSVs)
- **dbt project** (data modeling, transformations, quality tests)

## Quick Start

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and started
- Terminal access

### 1. Build and start containers

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

### 2. Run dbt (transformations + tests)

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

### 3. Stop everything

```bash
docker compose down
# Or to remove volumes:
docker compose down -v
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
- **`stg_leads`** — Deduplicated leads (by phone/email), typed, earliest record kept
- **`stg_appels`** — Filtered calls (removed orphans), typed, referential integrity enforced
- **`stg_contrats`** — Filtered contracts (removed orphans & temporal inconsistencies), typed
- **`stg_commerciaux`** — Clean sales rep data

#### Mart Models (`marts.*`)
- **`fct_performance`** — Commercial performance metrics (Part 1.2)
  - Total calls, connection rate, conversion rate per sales rep
- **`fct_conversions`** — Sales cycle analysis (Part 1.3)
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
docker compose run --rm dbt dbt test --select stg_leads
```  

Run tests on source data:
```bash
docker compose exec dbt dbt test --select source:raw
```

