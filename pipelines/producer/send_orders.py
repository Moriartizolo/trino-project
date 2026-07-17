import json
import sys
import time

from kafka import KafkaProducer

BOOTSTRAP = sys.argv[1] if len(sys.argv) > 1 else "localhost:9092"
TOPIC = "orders"

producer = KafkaProducer(
    bootstrap_servers=BOOTSTRAP,
    value_serializer=lambda value: json.dumps(value).encode("utf-8"),
)

sample_orders = [
    {"order_id": 101, "customer": "Alice", "amount": 150.0},
    {"order_id": 102, "customer": "Bob", "amount": 89.5},
    {"order_id": 103, "customer": "Charlie", "amount": 220.0},
]

for order in sample_orders:
    producer.send(TOPIC, order)
    print(f"Sent: {order}")
    time.sleep(0.5)

producer.flush()
print("Done")
