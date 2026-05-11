# Credit Risk Platform

A small, containerized **data engineering practice project** that simulates a bank-style **credit risk analytics pipeline**.

It ingests mock “API” JSON datasets into PostgreSQL, transforms and tests the data with dbt, and orchestrates the full workflow with Apache Airflow.

## What this project does

- **Generates mock operational data** (loan applications + transactions) as JSON (optional step).
- **Loads raw-like JSON data** into PostgreSQL (`credit_risk_data` schema).
- **Runs dbt seeds/models/tests** to produce clean staging views, intermediate business logic views, and final marts (tables).
- **Orchestrates the end-to-end pipeline** in Airflow as a daily DAG.

## Tech stack

- **Apache Airflow 3.1.8** (LocalExecutor, API server)
- **PostgreSQL 15**
- **dbt Core + dbt-postgres**
- **Python scripts** (ingestion + mock data generator)
- **Docker + Docker Compose**

## Repo structure

```text
credit_risk_platform/
├── airflow/
│   ├── dags/                    # DAG definitions
│   ├── logs/                    # Airflow logs (also used for dbt log/target dirs)
│   └── plugins/                 # Airflow plugins (empty by default)
├── data/
│   └── api_mock/                # Mock “API responses” as JSON
├── dbt/
│   ├── profiles.yml             # dbt profile using env vars
│   └── credit_risk/             # dbt project: seeds, models, tests
├── docker/
│   ├── Dockerfile.airflow       # Airflow image + Python deps (dbt, psycopg2, Faker, etc.)
│   ├── Dockerfile.dbt           # Standalone dbt container
│   └── Dockerfile.python        # Standalone Python container for scripts
├── scripts/
│   ├── generate_mock_api_data.py
│   └── load_api_data_to_postgres.py
├── docker-compose.yml
├── requirements.txt
└── README.md
```

## Docs

- `docs/ARCHITECTURE.md`: components + high-level architecture/dataflow diagram
- `docs/RUNBOOK.md`: day-to-day commands (start/stop/reset, trigger DAGs, run dbt, reload data)
- `docs/TROUBLESHOOTING.md`: common failures and fixes (Airflow Execution API/JWT, dbt permissions, Postgres connectivity)

## End-to-end dataflow

### 1) Mock “API” data (JSON)

- **Generator**: `scripts/generate_mock_api_data.py`
- **Output**: `data/api_mock/loan_applications.json`, `data/api_mock/transactions.json`

### 2) Load JSON into Postgres (raw-ish tables)

- **Loader**: `scripts/load_api_data_to_postgres.py`
- **Reads from**: `/opt/data/api_mock` (mounted from `./data/api_mock`)
- **Writes to**: Postgres schema `credit_risk_data`
- **Creates/overwrites**:
  - `credit_risk_data.loan_applications`
  - `credit_risk_data.transactions`

### 3) dbt seeds (reference tables)

CSV seeds in `dbt/credit_risk/seeds/` load into `credit_risk_data`:

- `customers.csv`
- `loan_products.csv`
- `credit_score_bands.csv`

### 4) dbt models + tests

dbt profile: `dbt/profiles.yml` (uses `DBT_POSTGRES_*` env vars).

- **Staging** (`dbt/credit_risk/models/staging/`): standardized views
- **Intermediate** (`dbt/credit_risk/models/intermediate/`): business logic views
- **Mart** (`dbt/credit_risk/models/mart/`): final analytics tables

Tests are declared in the `schema.yml` files under the models directories.

### 5) Airflow orchestration

DAG: `airflow/dags/credit_risk_pipeline.py`

Task order:

1. `load_api_data` (runs the ingestion script)
2. `dbt_seed`
3. `dbt_run_staging` → `dbt_test_staging`
4. `dbt_run_intermediate` → `dbt_test_intermediate`
5. `dbt_run_mart` → `dbt_test_mart`

## Running the project (Docker)

### Prerequisites

- Docker Desktop (or Docker Engine) with Compose support

### 1) Configure environment

```bash
cp .env.example .env
```

Minimum required variables:

- **Postgres**: `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- **Airflow metadata DB**: `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN`
- **Airflow execution API auth**: `AIRFLOW__API_AUTH__JWT_SECRET`

### 2) Start services

```bash
docker compose up -d --build
docker compose ps
```

### 3) Open Airflow UI

- **URL**: `http://localhost:8080/`

### 4) (Optional) regenerate mock JSON

```bash
docker compose run --rm python python /opt/scripts/generate_mock_api_data.py
```

### 5) Run the pipeline

- **Via Airflow UI**: unpause + trigger `credit_risk_pipeline`

Or run steps manually:

```bash
docker compose run --rm python python /opt/scripts/load_api_data_to_postgres.py
docker compose run --rm dbt dbt seed --project-dir /opt/dbt/credit_risk --profiles-dir /opt/dbt
docker compose run --rm dbt dbt run  --project-dir /opt/dbt/credit_risk --profiles-dir /opt/dbt
docker compose run --rm dbt dbt test --project-dir /opt/dbt/credit_risk --profiles-dir /opt/dbt
```

## Important configuration notes

### Airflow 3: Execution API URL + JWT secret

This compose stack runs separate Airflow containers (`api-server`, `scheduler`, `dag-processor`). In Airflow 3, task execution uses the **Execution API**.

`docker-compose.yml` sets:

- `AIRFLOW__CORE__EXECUTION_API_SERVER_URL=http://airflow-api-server:8080/execution/`
- `AIRFLOW__API_AUTH__JWT_SECRET` (must be the same across all Airflow services)

### dbt log/target paths inside Airflow containers

To avoid dbt writing logs/artifacts into bind-mounted project directories (which can be non-writable on Windows), `docker-compose.yml` sets:

- `DBT_LOG_PATH=/opt/airflow/logs/dbt_logs`
- `DBT_TARGET_PATH=/opt/airflow/logs/dbt_target`

## What you can query after a run

Schema: `credit_risk_data`

- **Ingested tables**: `loan_applications`, `transactions`
- **Seed tables**: `customers`, `loan_products`, `credit_score_bands`
- **Final marts**: `mart_*` models in `dbt/credit_risk/models/mart/`

## Troubleshooting

See `docs/TROUBLESHOOTING.md`.

## License

MIT