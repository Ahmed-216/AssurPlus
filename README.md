# AssurPlus - Analytics Engineer Case Study

# Overview

This repository contains a complete analytics engineering solution for AssurPlus, including:

- **Raw data** (CSV files in `raw_data/`)
- **Postgres database** (Docker-based, auto-loads CSVs)
- **dbt project** (data modeling, transformations, quality tests)
- **Metabase** (BI tool for dashboards and visualizations)

# Setup

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and **started**
- Terminal access

### Clone the repository

```bash
git clone https://github.com/Ahmed-216/AssurPlus.git
cd AssurPlus
```


## Build and start containers

Build the dbt Docker image:
```bash
docker compose build dbt
```

Start all containers:
```bash
docker compose up -d
```

This will:
- Start Postgres on `localhost:5432`
- Auto-load CSVs from `raw_data/` into `raw.*` tables
- Start dbt container (waits for Postgres to be healthy)
- Start Metabase on `localhost:3000` for dashboards and visualizations

> **Note:** Metabase may take several minutes to start on first run (~500MB download). 


#  Run dbt (transformations + tests)

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
docker compose exec dbt dbt docs serve --port 8181
```

Then open http://localhost:8181 in your browser.

# Access Metabase (BI Dashboard)

> **Important:** Make sur you have already run dbt (`docker compose exec dbt dbt run`) to create staging and marts schemas and tables before using Metabase dashboard.

The dashboard will be available at: [http://localhost:3000/dashboard/2-dashboard](http://localhost:3000/dashboard/2-dashboard)

**Login credentials:**
- **Email**: admin@assurplus.fr
- **Password**: admin10  



--


# Data Structure

## Raw Tables (loaded from CSVs)

Located in `raw.*` schema :

- **`raw.leads`** — Lead data from CRM
- **`raw.appels`** — Call history
- **`raw.contrats`** — Signed contracts
- **`raw.commerciaux`** — Sales team roster


## dbt Models

### Staging Models (`staging.*`)
Clean, typed, deduplicated foundation for all analytics:
- **`leads`** — Cleaned leads, typed, invalid commercial references filtered
- **`appels`** — Cleaned calls, typed, invalid foreign keys set to NULL
- **`contrats`** — Cleaned contracts, typed, temporal inconsistencies filtered
- **`commerciaux`** — Clean sales rep data

### Mart Models (`marts.*`)
- **`commercial_performance`** — Commercial performance metrics (Part 1.2)
  - Total calls, connection rate, conversion rate per sales rep
- **`contrats_stat`** — Sales cycle analysis (Part 1.3)
  - Number of calls before signature, time to conversion, delays
- **`funnel_analysis`** — Complete funnel tracking from lead creation to conversion  

--  


## Cleanup

When you're **done working with the project** :
```bash
docker compose down
```  