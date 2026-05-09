import json
import os
import psycopg2
from psycopg2.extras import execute_values

DB_CONFIG = {
    "host": os.getenv("DBT_POSTGRES_HOST", "postgres"),
    "dbname": os.getenv("DBT_POSTGRES_DB", "credit_risk"),
    "user": os.getenv("DBT_POSTGRES_USER", "admin"),
    "password": os.getenv("DBT_POSTGRES_PASSWORD", "supersecret"),
    "port": int(os.getenv("DBT_POSTGRES_PORT", 5432)),
}

DATA_DIR = "/opt/data/api_mock"


def get_connection():
    return psycopg2.connect(**DB_CONFIG)


def create_schema(conn):
    with conn.cursor() as cur:
        cur.execute("CREATE SCHEMA IF NOT EXISTS credit_risk_data;")
    conn.commit()
    print("Schema credit_risk_data ready")


def load_loan_applications(conn):
    filepath = os.path.join(DATA_DIR, "loan_applications.json")
    with open(filepath) as f:
        data = json.load(f)

    with conn.cursor() as cur:
        cur.execute("DROP TABLE IF EXISTS credit_risk_data.loan_applications;")
        cur.execute("""
            CREATE TABLE credit_risk_data.loan_applications (
                application_id      INTEGER PRIMARY KEY,
                customer_id         INTEGER,
                product_id          INTEGER,
                requested_amount    NUMERIC,
                credit_score        INTEGER,
                annual_income       NUMERIC,
                debt_to_income_ratio NUMERIC,
                employment_status   VARCHAR(50),
                loan_status         VARCHAR(50),
                applied_at          TIMESTAMP,
                reviewed_at         TIMESTAMP
            );
        """)
        rows = [
            (
                r["application_id"], r["customer_id"], r["product_id"],
                r["requested_amount"], r["credit_score"], r["annual_income"],
                r["debt_to_income_ratio"], r["employment_status"],
                r["loan_status"], r["applied_at"], r.get("reviewed_at")
            )
            for r in data
        ]
        execute_values(cur, """
            INSERT INTO credit_risk_data.loan_applications VALUES %s
        """, rows)
    conn.commit()
    print(f"Loaded {len(rows)} loan applications")


def load_transactions(conn):
    filepath = os.path.join(DATA_DIR, "transactions.json")
    with open(filepath) as f:
        data = json.load(f)

    with conn.cursor() as cur:
        cur.execute("DROP TABLE IF EXISTS credit_risk_data.transactions;")
        cur.execute("""
            CREATE TABLE credit_risk_data.transactions (
                transaction_id      INTEGER PRIMARY KEY,
                customer_id         INTEGER,
                transaction_type    VARCHAR(50),
                amount              NUMERIC,
                balance_after       NUMERIC,
                currency            VARCHAR(10),
                status              VARCHAR(50),
                merchant            VARCHAR(255),
                description         TEXT,
                created_at          TIMESTAMP
            );
        """)
        rows = [
            (
                r["transaction_id"], r["customer_id"], r["transaction_type"],
                r["amount"], r["balance_after"], r["currency"],
                r["status"], r.get("merchant"), r["description"], r["created_at"]
            )
            for r in data
        ]
        execute_values(cur, """
            INSERT INTO credit_risk_data.transactions VALUES %s
        """, rows)
    conn.commit()
    print(f"Loaded {len(rows)} transactions")


if __name__ == "__main__":
    print("Loading API data into PostgreSQL...")
    conn = get_connection()
    create_schema(conn)
    load_loan_applications(conn)
    load_transactions(conn)
    conn.close()
    print("Done!")