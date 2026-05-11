# Architecture

## High-level diagram

```text
data/api_mock/*.json
        |
        |  (Python) scripts/load_api_data_to_postgres.py
        v
PostgreSQL (schema: credit_risk_data)
  - loan_applications
  - transactions
  - customers (seed)
  - loan_products (seed)
  - credit_score_bands (seed)
        |
        |  (dbt) seeds + models + tests
        v
Analytics outputs (schema: credit_risk_data)
  - stg_* (views)
  - int_* (views)
  - mart_* (tables)
        |
        |  (Airflow) airflow/dags/credit_risk_pipeline.py
        v
Scheduled + observable pipeline runs
```

## Components

### PostgreSQL

- **Purpose**: stores ingestion tables, seed tables, and dbt model outputs.
- **Container**: `postgres` (Docker image `postgres:15`).
- **Port**: exposed on host as `5433` (container `5432`).

### Python scripts

- `scripts/generate_mock_api_data.py`
  - creates JSON mock “API” data under `data/api_mock/`.
- `scripts/load_api_data_to_postgres.py`
  - loads JSON files into `credit_risk_data.loan_applications` and `credit_risk_data.transactions`.
  - uses `DBT_POSTGRES_*` env vars for connectivity (shared with dbt profile).

### dbt project

- **Location**: `dbt/credit_risk/`
- **Profile**: `dbt/profiles.yml` (reads `DBT_POSTGRES_*`)
- **Schema**: `credit_risk_data`
- **Layers**:
  - **Staging**: `models/staging/`
  - **Intermediate**: `models/intermediate/`
  - **Mart**: `models/mart/`

### Airflow orchestration

- **DAG**: `airflow/dags/credit_risk_pipeline.py`
- **Executor**: `LocalExecutor`
- **API server**: `airflow-api-server` (`docker compose` service) exposes `:8080`

Airflow 3 runs tasks via an **Execution API** endpoint. In this stack it is configured to talk to the API server container over the docker network:

- `AIRFLOW__CORE__EXECUTION_API_SERVER_URL=http://airflow-api-server:8080/execution/`

Execution API requests use JWT authentication and require:

- `AIRFLOW__API_AUTH__JWT_SECRET` set and identical for all Airflow services.

