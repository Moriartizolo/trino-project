import base64
import json
import os
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone

import psycopg2
from confluent_kafka import Consumer, KafkaError

KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP", "kafka:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "transactions")
CLICKHOUSE_URL = os.getenv("CLICKHOUSE_URL", "http://clickhouse:8123")
CLICKHOUSE_USER = os.getenv("CLICKHOUSE_USER", "default")
CLICKHOUSE_PASSWORD = os.getenv("CLICKHOUSE_PASSWORD", "clickhouse")
CONSUMER_GROUP = os.getenv("CONSUMER_GROUP", "transactions-consumer")
TRINO_URL = os.getenv("TRINO_URL", "http://trino:8081")
TRINO_USER = os.getenv("TRINO_USER", "admin")
POSTGRES_HOST = os.getenv("POSTGRES_HOST", "postgres")
POSTGRES_DB = os.getenv("POSTGRES_DB", "iceberg_meta")
POSTGRES_USER = os.getenv("POSTGRES_USER", "admin")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "password")


def default_str(value, fallback: str) -> str:
    return str(value) if value is not None else fallback


def default_int(value, fallback: int) -> int:
    return int(value) if value is not None else fallback


def normalize_transaction(payload: dict) -> dict:
    transaction_id = payload.get("transaction_id", payload.get("order_id"))
    if transaction_id is None:
        raise KeyError("transaction_id")

    customer_id = payload.get("customer_id")
    if customer_id is None and payload.get("customer") is not None:
        customer_id = abs(hash(str(payload["customer"]))) % 1_000_000_000
    if customer_id is None:
        customer_id = 0

    transaction_time = payload.get("transaction_time")
    if transaction_time is None:
        transaction_time = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")

    return {
        "transaction_id": int(transaction_id),
        "customer_id": int(customer_id),
        "transaction_time": transaction_time,
        "amount": float(payload.get("amount", 0)),
        "currency": default_str(payload.get("currency"), "RUB"),
        "channel": default_str(payload.get("channel"), "mobile"),
        "operation_type": default_str(payload.get("operation_type"), "payment"),
        "status": default_str(payload.get("status"), "success"),
        "country": default_str(payload.get("country"), "RU"),
        "processing_time_ms": default_int(payload.get("processing_time_ms"), 0),
        "customer_segment": default_str(payload.get("customer_segment"), "mass"),
        "region": default_str(payload.get("region"), "unknown"),
        "customer_risk_level": default_str(payload.get("customer_risk_level"), "low"),
        "total_risk_score": default_int(payload.get("total_risk_score"), 0),
        "transaction_risk_level": default_str(payload.get("transaction_risk_level"), "low"),
        "final_decision": default_str(payload.get("final_decision"), "allow"),
        "fraud_detection_time_ms": default_int(payload.get("fraud_detection_time_ms"), 0),
        "triggered_rules_count": default_int(payload.get("triggered_rules_count"), 0),
        "alerts_count": default_int(payload.get("alerts_count"), 0),
    }


def insert_postgres(transaction: dict) -> None:
    query = """
        INSERT INTO fintech.transactions (
            transaction_id, customer_id, transaction_time, currency, channel,
            operation_type, status, country, processing_time_ms
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (transaction_id) DO NOTHING
    """
    values = (
        transaction["transaction_id"],
        transaction["customer_id"],
        transaction["transaction_time"],
        transaction["currency"],
        transaction["channel"],
        transaction["operation_type"],
        transaction["status"],
        transaction["country"],
        transaction["processing_time_ms"],
    )
    with psycopg2.connect(
        host=POSTGRES_HOST,
        dbname=POSTGRES_DB,
        user=POSTGRES_USER,
        password=POSTGRES_PASSWORD,
    ) as connection:
        with connection.cursor() as cursor:
            cursor.execute(query, values)
        connection.commit()


def insert_clickhouse(transaction: dict) -> None:
    row = {
        "transaction_id": transaction["transaction_id"],
        "customer_id": transaction["customer_id"],
        "transaction_time": transaction["transaction_time"],
        "amount": transaction["amount"],
        "customer_segment": transaction["customer_segment"],
        "region": transaction["region"],
        "customer_risk_level": transaction["customer_risk_level"],
        "total_risk_score": transaction["total_risk_score"],
        "transaction_risk_level": transaction["transaction_risk_level"],
        "final_decision": transaction["final_decision"],
        "fraud_detection_time_ms": transaction["fraud_detection_time_ms"],
        "triggered_rules_count": transaction["triggered_rules_count"],
        "alerts_count": transaction["alerts_count"],
    }
    query = (
        "INSERT INTO fintech.transaction_analytics FORMAT JSONEachRow\n"
        f"{json.dumps(row)}"
    )
    request = urllib.request.Request(
        CLICKHOUSE_URL,
        data=query.encode("utf-8"),
        method="POST",
    )
    credentials = base64.b64encode(
        f"{CLICKHOUSE_USER}:{CLICKHOUSE_PASSWORD}".encode("utf-8")
    ).decode("ascii")
    request.add_header("Authorization", f"Basic {credentials}")
    with urllib.request.urlopen(request, timeout=10) as response:
        response.read()


def sql_literal(value) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, (int, float)):
        return str(value)
    escaped = str(value).replace("'", "''")
    return f"'{escaped}'"


def trino_execute(query: str) -> None:
    request = urllib.request.Request(
        f"{TRINO_URL}/v1/statement",
        data=query.encode("utf-8"),
        method="POST",
        headers={"X-Trino-User": TRINO_USER, "Content-Type": "text/plain"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        payload = json.loads(response.read().decode("utf-8"))

    next_uri = payload.get("nextUri")
    while next_uri:
        with urllib.request.urlopen(next_uri, timeout=30) as response:
            payload = json.loads(response.read().decode("utf-8"))
        if payload.get("error"):
            raise RuntimeError(payload["error"]["message"])
        next_uri = payload.get("nextUri")


def insert_iceberg(transaction: dict) -> None:
    query = f"""
        INSERT INTO iceberg.fintech.transaction_facts VALUES (
            {transaction["transaction_id"]},
            {transaction["customer_id"]},
            TIMESTAMP {sql_literal(transaction["transaction_time"])},
            {transaction["amount"]},
            {sql_literal(transaction["currency"])},
            {sql_literal(transaction["channel"])},
            {sql_literal(transaction["operation_type"])},
            {sql_literal(transaction["status"])},
            {sql_literal(transaction["country"])},
            {transaction["processing_time_ms"]},
            {sql_literal(transaction["customer_segment"])},
            {sql_literal(transaction["region"])},
            {sql_literal(transaction["customer_risk_level"])},
            {transaction["total_risk_score"]},
            {sql_literal(transaction["transaction_risk_level"])},
            {sql_literal(transaction["final_decision"])},
            {transaction["fraud_detection_time_ms"]},
            {transaction["triggered_rules_count"]},
            {transaction["alerts_count"]},
            CURRENT_TIMESTAMP
        )
    """
    trino_execute(query)


def save_transaction(transaction: dict) -> None:
    insert_postgres(transaction)
    insert_iceberg(transaction)
    insert_clickhouse(transaction)


def main() -> None:
    print(f"Waiting for Kafka at {KAFKA_BOOTSTRAP}, topic={KAFKA_TOPIC}")

    consumer = Consumer({
        "bootstrap.servers": KAFKA_BOOTSTRAP,
        "group.id": CONSUMER_GROUP,
        "auto.offset.reset": "earliest",
    })
    consumer.subscribe([KAFKA_TOPIC])

    print("Consumer started")

    while True:
        message = consumer.poll(1.0)
        if message is None:
            continue
        if message.error():
            if message.error().code() != KafkaError._PARTITION_EOF:
                print(f"Kafka error: {message.error()}", file=sys.stderr)
            continue

        try:
            payload = json.loads(message.value().decode("utf-8"))
            transaction = normalize_transaction(payload)
            save_transaction(transaction)
            print(
                f"Saved transaction {transaction['transaction_id']} "
                "(postgres + iceberg + clickhouse)"
            )
        except (
            KeyError,
            TypeError,
            ValueError,
            urllib.error.URLError,
            json.JSONDecodeError,
            RuntimeError,
            psycopg2.Error,
        ) as error:
            print(f"Failed to process message: {message.value()!r} ({error})", file=sys.stderr)


if __name__ == "__main__":
    main()
