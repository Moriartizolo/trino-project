# trino-project

Учебная **гибридная lakehouse-платформа** для финтех-сценария (антифрод / транзакции).  
Стек: **Kafka → consumer → PostgreSQL + Iceberg (MinIO) + ClickHouse**, единый SQL-доступ через **Trino**, мониторинг **Prometheus + Grafana**.

## Архитектура

```
Kafka (topic: transactions)
        ↓
   kafka-consumer
        ├── PostgreSQL   fintech.transactions          — операционный реестр
        ├── Iceberg/MinIO fintech.transaction_facts   — data lake (полный архив)
        └── ClickHouse   fintech.transaction_analytics — аналитический срез

Trino — SQL ко всем хранилищам (postgres.*, iceberg.*, clickhouse.*)
```

| Слой | Хранилище | Таблица | Роль |
|------|-----------|---------|------|
| 1 | PostgreSQL | `fintech.transactions` | Операционка — что произошло (10 колонок) |
| 2 | MinIO + Iceberg | `fintech.transaction_facts` | Data lake — полная копия полей (20 колонок) |
| 3 | ClickHouse | `fintech.transaction_analytics` | Аналитика для Grafana (14 колонок) |

**Связь:** `transaction_id` — общий ключ во всех трёх таблицах.

Подробная схема: [`docs/fintech-data-architecture.pdf`](docs/fintech-data-architecture.pdf)

## Компоненты

| Сервис | Назначение |
|--------|------------|
| **Kafka** | Приём потока событий |
| **kafka-consumer** | Python-пайплайн: JSON → PG + Iceberg + ClickHouse |
| **PostgreSQL** | Операционные данные + метаданные Iceberg JDBC catalog |
| **MinIO** | S3-совместимое хранилище файлов (parquet) |
| **Iceberg** | Open table format поверх MinIO |
| **ClickHouse** | Быстрая OLAP-аналитика |
| **Trino** | Federated SQL engine |
| **Prometheus + Grafana** | Мониторинг |
| **Kafka UI** | Просмотр топиков и отправка сообщений |

## Требования

- Docker Desktop (или Docker Engine + Docker Compose v2)
- ~8 GB RAM (рекомендуется)

## Быстрый старт

```bash
git clone <repo-url>
cd trino-project

docker compose up -d --build
```

Первый запуск или смена схемы — с чистыми volumes:

```bash
docker compose down -v
docker compose up -d --build
```

Проверка статуса:

```bash
docker compose ps
```

## Порты и UI

| Сервис | URL | Учётные данные |
|--------|-----|----------------|
| Trino | http://localhost:8081/ui/ | — |
| Grafana | http://localhost:3000 | admin / admin |
| Prometheus | http://localhost:9090 | — |
| Kafka UI | http://localhost:8090 | — |
| MinIO Console | http://localhost:9001 | admin / password |
| PostgreSQL | localhost:5432 | admin / password |
| ClickHouse HTTP | localhost:8123 | default / clickhouse |
| Kafka | localhost:9092 | — |

## Проверка данных

Через Trino CLI (без Web UI):

```bash
docker exec trino-coordinator trino --server http://localhost:8081 --execute \
  "SELECT count(*) FROM postgres.fintech.transactions"

docker exec trino-coordinator trino --server http://localhost:8081 --execute \
  "SELECT count(*) FROM iceberg.fintech.transaction_facts"

docker exec trino-coordinator trino --server http://localhost:8081 --execute \
  "SELECT count(*) FROM clickhouse.fintech.transaction_analytics"
```

После init в каждой таблице **5 тестовых строк** (transaction_id 1001–1005).

## Загрузка данных через Kafka

1. Открой Kafka UI: http://localhost:8090  
2. Topic: `transactions` → **Produce Message**  
3. Отправь JSON:

```json
{
  "transaction_id": 3001,
  "customer_id": 701,
  "amount": 1234.56,
  "channel": "mobile",
  "status": "success",
  "customer_segment": "premium",
  "region": "Moscow",
  "final_decision": "allow"
}
```

4. Проверь лог consumer:

```bash
docker logs kafka-consumer --tail 10
```

Ожидаемо: `Saved transaction 3001 (postgres + iceberg + clickhouse)`.

## Загрузка данных через Trino

Trino **не пишет одной командой** во все таблицы — нужны **три отдельных INSERT** (разные каталоги и наборы колонок):

```sql
-- PostgreSQL (10 полей)
INSERT INTO postgres.fintech.transactions (
    transaction_id, customer_id, transaction_time, currency, channel,
    operation_type, status, country, processing_time_ms
) VALUES (
    4001, 801, TIMESTAMP '2026-01-20 12:00:00',
    'RUB', 'mobile', 'payment', 'success', 'RU', 110
);

-- Iceberg / MinIO (20 полей)
INSERT INTO iceberg.fintech.transaction_facts VALUES (
    4001, 801, TIMESTAMP '2026-01-20 12:00:00', 5000.00,
    'RUB', 'mobile', 'payment', 'success', 'RU', 110,
    'mass', 'Moscow', 'low', 20, 'low', 'allow', 40, 0, 0,
    CURRENT_TIMESTAMP
);

-- ClickHouse (14 полей)
INSERT INTO clickhouse.fintech.transaction_analytics (
    transaction_id, customer_id, transaction_time, amount,
    customer_segment, region, customer_risk_level,
    total_risk_score, transaction_risk_level, final_decision,
    fraud_detection_time_ms, triggered_rules_count, alerts_count
) VALUES (
    4001, 801, TIMESTAMP '2026-01-20 12:00:00', 5000.00,
    'mass', 'Moscow', 'low', 20, 'low', 'allow', 40, 0, 0
);
```

CLI:

```bash
docker exec -it trino-coordinator trino --server http://localhost:8081
```

## Kafka consumer

Сервис `pipelines/consumer/consumer.py`:

1. Читает JSON из топика `transactions`
2. Нормализует поля (дефолты для currency, channel, risk и т.д.)
3. Пишет в три хранилища:
   - **PostgreSQL** — напрямую (`psycopg2`)
   - **ClickHouse** — HTTP API
   - **Iceberg** — через Trino REST API → файлы в MinIO

## Структура проекта

```
trino-project/
├── docker-compose.yaml          # весь стек
├── init-scripts/
│   ├── 01-init.sql              # PostgreSQL: Iceberg metadata + user trino
│   ├── 02-fintech-transactions.sql
│   └── trino/01-iceberg-fintech.sql
├── clickhouse/init/01-init.sql
├── pipelines/consumer/          # Kafka → PG + Iceberg + ClickHouse
├── trino-catalog/               # postgres, iceberg, clickhouse
├── trino-config/
├── monitoring/                  # Prometheus, Grafana
└── docs/
    └── fintech-data-architecture.pdf
```

## Trino catalogs

| Catalog | Подключение |
|---------|-------------|
| `postgres` | PostgreSQL `iceberg_meta` |
| `iceberg` | JDBC catalog → MinIO (`s3://iceberg-bucket-warehouse/`) |
| `clickhouse` | ClickHouse JDBC |

## Мониторинг

- **Prometheus** собирает метрики Trino, PostgreSQL (postgres-exporter), MinIO
- **Grafana** — дашборд `Data Platform Overview` (provisioning из `monitoring/grafana/`)

## Остановка

```bash
docker compose down
```

Удалить все данные (volumes):

```bash
docker compose down -v
```
