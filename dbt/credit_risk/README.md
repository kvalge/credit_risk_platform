# dbt project: `credit_risk`

This dbt project transforms ingested “raw-ish” credit risk data in PostgreSQL into analytics-ready marts.

## Where the data lands

- **Database**: from `DBT_POSTGRES_DB`
- **Schema**: `credit_risk_data` (see `dbt/profiles.yml`)

## Inputs

### Seed tables (`seeds/`)

- `customers.csv`
- `loan_products.csv`
- `credit_score_bands.csv`

### Ingested tables (loaded by Python)

- `credit_risk_data.loan_applications`
- `credit_risk_data.transactions`

## Layers

- **Staging models**: `models/staging/` (views)
- **Intermediate models**: `models/intermediate/` (views)
- **Mart models**: `models/mart/` (tables)

## Common commands

From the repo root (Docker):

```bash
docker compose run --rm dbt dbt seed --project-dir /opt/dbt/credit_risk --profiles-dir /opt/dbt
docker compose run --rm dbt dbt run  --project-dir /opt/dbt/credit_risk --profiles-dir /opt/dbt
docker compose run --rm dbt dbt test --project-dir /opt/dbt/credit_risk --profiles-dir /opt/dbt
```

Or inside the Airflow containers dbt is available at `/home/airflow/.local/bin/dbt`.
