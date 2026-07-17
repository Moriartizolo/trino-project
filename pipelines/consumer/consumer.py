import base64
import json
import os
import sys
import urllib.error
import urllib.request

from confluent_kafka import Consumer, KafkaError

KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP", "kafka:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "orders")
CLICKHOUSE_URL = os.getenv("CLICKHOUSE_URL", "http://clickhouse:8123")
CLICKHOUSE_USER = os.getenv("CLICKHOUSE_USER", "default")
CLICKHOUSE_PASSWORD = os.getenv("CLICKHOUSE_PASSWORD", "clickhouse")
CONSUMER_GROUP = os.getenv("CONSUMER_GROUP", "orders-consumer")


def insert_order(order: dict) -> None:
    row = {
        "order_id": int(order["order_id"]),
        "customer": str(order["customer"]),
        "amount": float(order["amount"]),
    }
    query = f"INSERT INTO analytics.orders FORMAT JSONEachRow\n{json.dumps(row)}"
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
            order = json.loads(message.value().decode("utf-8"))
            insert_order(order)
            print(f"Saved order {order['order_id']} for {order['customer']}")
        except (KeyError, TypeError, ValueError, urllib.error.URLError, json.JSONDecodeError) as error:
            print(f"Failed to process message: {message.value()!r} ({error})", file=sys.stderr)


if __name__ == "__main__":
    main()
