from datetime import datetime, timedelta

from airflow import DAG
from airflow.providers.standard.operators.bash import BashOperator

default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(seconds=10),
}

DBT_FLAGS = "--project-dir /opt/dbt/credit_risk --profiles-dir /opt/dbt"
PYTHON = "/home/airflow/.local/bin/python"
DBT = "/home/airflow/.local/bin/dbt"

with DAG(
    dag_id="credit_risk_pipeline",
    default_args=default_args,
    description="Full credit risk data pipeline: ingest, transform, test",
    schedule="@daily",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["credit_risk", "dbt", "postgres"],
) as dag:

    load_api_data = BashOperator(
        task_id="load_api_data",
        bash_command=f"{PYTHON} /opt/scripts/load_api_data_to_postgres.py",
    )

    dbt_seed = BashOperator(
        task_id="dbt_seed",
        bash_command=f"{DBT} seed {DBT_FLAGS}",
    )

    dbt_run_staging = BashOperator(
        task_id="dbt_run_staging",
        bash_command=f"{DBT} run --select staging {DBT_FLAGS}",
    )

    dbt_test_staging = BashOperator(
        task_id="dbt_test_staging",
        bash_command=f"{DBT} test --select staging {DBT_FLAGS}",
    )

    dbt_run_intermediate = BashOperator(
        task_id="dbt_run_intermediate",
        bash_command=f"{DBT} run --select intermediate {DBT_FLAGS}",
    )

    dbt_test_intermediate = BashOperator(
        task_id="dbt_test_intermediate",
        bash_command=f"{DBT} test --select intermediate {DBT_FLAGS}",
    )

    dbt_run_mart = BashOperator(
        task_id="dbt_run_mart",
        bash_command=f"{DBT} run --select mart {DBT_FLAGS}",
    )

    dbt_test_mart = BashOperator(
        task_id="dbt_test_mart",
        bash_command=f"{DBT} test --select mart {DBT_FLAGS}",
    )

    # Pipeline order
    load_api_data >> dbt_seed >> dbt_run_staging >> dbt_test_staging
    dbt_test_staging >> dbt_run_intermediate >> dbt_test_intermediate
    dbt_test_intermediate >> dbt_run_mart >> dbt_test_mart
