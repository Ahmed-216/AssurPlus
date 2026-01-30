FROM python:3.11-slim

# Install dbt (adapter for Postgres).
# Note: dbt-utils and dbt-expectations are dbt *packages* (installed via `dbt deps`),
# not pip packages.
# Use dbt 1.6.x and pin protobuf to avoid the MessageToJson() incompatibility.
RUN pip install --no-cache-dir \
    "dbt-postgres==1.6.7" \
    "protobuf<5"

WORKDIR /usr/app
