import json
import random
import os
from datetime import datetime, timedelta
from faker import Faker

fake = Faker()
random.seed(42)

OUTPUT_DIR = "/opt/data/api_mock"
os.makedirs(OUTPUT_DIR, exist_ok=True)

LOAN_STATUSES = ["pending", "approved", "rejected", "disbursed", "defaulted", "closed"]
TRANSACTION_TYPES = ["deposit", "withdrawal", "transfer", "payment", "refund"]
EMPLOYMENT_STATUSES = ["employed", "self_employed", "unemployed", "retired"]


def generate_loan_applications(n=50):
    applications = []
    for i in range(1, n + 1):
        customer_id = random.randint(1, 10)
        product_id = random.randint(1, 10)
        requested_amount = round(random.uniform(1000, 500000), 2)
        credit_score = random.randint(300, 850)
        applied_at = fake.date_time_between(
            start_date="-1y", end_date="now"
        )

        applications.append({
            "application_id": i,
            "customer_id": customer_id,
            "product_id": product_id,
            "requested_amount": requested_amount,
            "credit_score": credit_score,
            "annual_income": round(random.uniform(20000, 200000), 2),
            "debt_to_income_ratio": round(random.uniform(0.05, 0.65), 2),
            "employment_status": random.choice(EMPLOYMENT_STATUSES),
            "loan_status": random.choice(LOAN_STATUSES),
            "applied_at": applied_at,
            "reviewed_at": fake.date_time_between(
                start_date=applied_at, end_date="now"
            ).isoformat() if random.random() > 0.2 else None,
        })
    return applications


def generate_transactions(n=200):
    transactions = []
    for i in range(1, n + 1):
        amount = round(random.uniform(10, 50000), 2)
        transaction_type = random.choice(TRANSACTION_TYPES)

        transactions.append({
            "transaction_id": i,
            "customer_id": random.randint(1, 10),
            "transaction_type": transaction_type,
            "amount": amount,
            "balance_after": round(random.uniform(0, 100000), 2),
            "currency": "USD",
            "status": random.choice(["completed", "pending", "failed"]),
            "merchant": fake.company() if transaction_type in ["payment", "refund"] else None,
            "description": fake.sentence(nb_words=6),
            "created_at": fake.date_time_between(
                start_date="-1y", end_date="now"
            ).isoformat(),
        })
    return transactions


def save_json(data, filename):
    filepath = os.path.join(OUTPUT_DIR, filename)
    with open(filepath, "w") as f:
        json.dump(data, f, indent=2, default=str)
    print(f"Saved {len(data)} records to {filepath}")


if __name__ == "__main__":
    print("Generating mock API data...")

    loan_applications = generate_loan_applications(50)
    save_json(loan_applications, "loan_applications.json")

    transactions = generate_transactions(200)
    save_json(transactions, "transactions.json")

    print(f"Done! Generated at {datetime.now().isoformat()}")