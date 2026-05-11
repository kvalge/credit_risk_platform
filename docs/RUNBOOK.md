# Runbook

Practical commands for running and operating the **Credit Risk Platform** locally.

All commands below assume you are in the repo root (the folder containing `docker-compose.yml`).

## Start / stop

### Start the stack

```bash
docker compose up -d --build
docker compose ps
```

### Stop the stack (keep volumes/data)

```bash
docker compose down
```

### Stop the stack and delete Postgres data

This will wipe the Postgres volume.

```bash
docker compose down -v
```

## Airflow operations

### Open the UI

- `http://localhost:8080/`

### Recreate only Airflow services

Use this when you change Airflow-related environment variables in `.env` / `docker-compose.yml`.

```bash
docker compose up -d --force-recreate airflow-api-server airflow-scheduler airflow-dag-processor
docker compose ps
```

### List DAGs and task states (CLI inside container)

```bash
docker compose exec -T airflow-scheduler airflow dags list
docker compose exec -T airflow-scheduler airflow tasks list credit_risk_pipeline
```

### Trigger a run (CLI)

```bash
docker compose exec -T airflow-scheduler airflow dags trigger credit_risk_pipeline
```

### Debug a single task without scheduling (CLI)

This is useful for fast iteration; it runs the task “locally” for that logical date.

```bash
docker compose exec -T airflow-scheduler airflow tasks test credit_risk_pipeline load_api_data 2026-01-01
```

## Data operations

### (Optional) regenerate mock JSON

Writes to `data/api_mock/`.

```bash
docker compose run --rm python python /opt/scripts/generate_mock_api_data.py
```

### Reload JSON into Postgres

Creates/overwrites:
- `credit_risk_data.loan_applications`
- `credit_risk_data.transactions`

```bash
docker compose run --rm python python /opt/scripts/load_api_data_to_postgres.py
```

## dbt operations

### Seed / run / test (standalone dbt container)

```bash
docker compose run --rm dbt dbt seed --project-dir /opt/dbt/credit_risk --profiles-dir /opt/dbt
docker compose run --rm dbt dbt run  --project-dir /opt/dbt/credit_risk --profiles-dir /opt/dbt
docker compose run --rm dbt dbt test --project-dir /opt/dbt/credit_risk --profiles-dir /opt/dbt
```

### Run only one layer

```bash
docker compose run --rm dbt dbt run --select staging --project-dir /opt/dbt/credit_risk --profiles-dir /opt/dbt
docker compose run --rm dbt dbt run --select intermediate --project-dir /opt/dbt/credit_risk --profiles-dir /opt/dbt
docker compose run --rm dbt dbt run --select mart --project-dir /opt/dbt/credit_risk --profiles-dir /opt/dbt
```

## Common incidents and fixes

### 1) Airflow tasks fail immediately; task logs are empty (0 bytes)

**Likely cause**: Airflow 3 Execution API is misconfigured (URL or JWT secret), so the task never starts.

**Checks**

```bash
docker compose exec -T airflow-scheduler python -c "from airflow.configuration import conf; print(conf.get('core','execution_api_server_url', fallback=None))"
docker compose exec -T airflow-scheduler sh -c "env | grep AIRFLOW__API_AUTH__JWT_SECRET >/dev/null && echo JWT_SECRET_set || echo JWT_SECRET_missing"
docker compose exec -T airflow-api-server sh -c "env | grep AIRFLOW__API_AUTH__JWT_SECRET >/dev/null && echo JWT_SECRET_set || echo JWT_SECRET_missing"
```

**Fix**

- Ensure `.env` contains `AIRFLOW__API_AUTH__JWT_SECRET` and it is non-empty.
- Ensure `docker-compose.yml` sets:
  - `AIRFLOW__CORE__EXECUTION_API_SERVER_URL=http://airflow-api-server:8080/execution/`
  - `AIRFLOW__API_AUTH__JWT_SECRET=${AIRFLOW__API_AUTH__JWT_SECRET}`
- Recreate Airflow services:

```bash
docker compose up -d --force-recreate airflow-api-server airflow-scheduler airflow-dag-processor
```

### 2) dbt fails inside Airflow with permission errors writing logs/target

**Likely cause**: dbt writes into bind-mounted project paths that can be non-writable on Windows.

**Fix**

The stack is configured to redirect dbt logs/target into `/opt/airflow/logs` via:

- `DBT_LOG_PATH=/opt/airflow/logs/dbt_logs`
- `DBT_TARGET_PATH=/opt/airflow/logs/dbt_target`

If you change those values, recreate Airflow services.

### 3) Postgres connection errors

**Checks**

```bash
docker compose ps
docker compose logs postgres --tail 200
```

**Fix**

- Ensure `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` uses host `postgres` (not `localhost`).
- Ensure `DBT_POSTGRES_HOST=postgres` and `DBT_POSTGRES_PORT=5432`.

