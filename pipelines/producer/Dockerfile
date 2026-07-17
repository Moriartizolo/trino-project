FROM python:3.12-slim

WORKDIR /app

RUN pip install --no-cache-dir kafka-python==2.0.2

COPY send_orders.py .

CMD ["python", "send_orders.py", "kafka:9092"]
