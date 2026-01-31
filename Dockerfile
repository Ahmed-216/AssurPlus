FROM python:3.11-slim

# Install dbt (adapter for Postgres).
# Note: dbt-utils and dbt-expectations are dbt *packages* (installed via `dbt deps`),
RUN pip install --no-cache-dir \
    "dbt-postgres==1.6.7" \
    "protobuf<5"

WORKDIR /usr/app
