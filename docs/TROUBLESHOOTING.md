# Troubleshooting

## Airflow tasks fail immediately / logs are empty

### Symptom

- DAG run fails quickly.
- Task logs under `airflow/logs/.../attempt=*.log` are **0 bytes** (empty).

### Cause (Airflow 3.x)

Airflow 3 executes tasks via the **Execution API**. If the scheduler/worker cannot reach the API server, or cannot authenticate to it, tasks can fail before the user code runs.

### Fix

In `docker-compose.yml` (under `x-airflow-common.environment`), ensure:

- `AIRFLOW__CORE__EXECUTION_API_SERVER_URL=http://airflow-api-server:8080/execution/`
- `AIRFLOW__API_AUTH__JWT_SECRET` is set (via `.env`) and is the **same for all Airflow services**

Then recreate services:

```bash
docker compose up -d --force-recreate airflow-api-server airflow-scheduler airflow-dag-processor
```

## dbt fails inside Airflow with permission errors

### Symptom

dbt tasks fail with permission errors writing `dbt.log` or artifacts under `/opt/dbt/...`.

### Cause

On Windows bind mounts, directories under the dbt project can appear root-owned inside containers. Airflow runs tasks as the `airflow` user and may not be able to write there.

### Fix

The compose file sets:

- `DBT_LOG_PATH=/opt/airflow/logs/dbt_logs`
- `DBT_TARGET_PATH=/opt/airflow/logs/dbt_target`

These paths are writable because `./airflow/logs` is mounted at `/opt/airflow/logs`.

## Postgres connection issues

### Symptom

Ingestion script or dbt cannot connect to Postgres.

### Checks

- Verify Postgres is healthy: `docker compose ps`
- Ensure `.env` has consistent values:
  - `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
  - `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` points at `postgres` service (not `localhost`)
  - `DBT_POSTGRES_*` point at `postgres:5432`

