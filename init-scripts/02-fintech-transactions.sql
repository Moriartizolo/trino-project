CREATE SCHEMA IF NOT EXISTS fintech;

CREATE TABLE IF NOT EXISTS fintech.transactions (
    transaction_id       BIGINT PRIMARY KEY,
    customer_id          BIGINT NOT NULL,
    transaction_time     TIMESTAMP NOT NULL,
    currency             VARCHAR(3) NOT NULL,
    channel              VARCHAR(32) NOT NULL,
    operation_type       VARCHAR(32) NOT NULL,
    status               VARCHAR(16) NOT NULL,
    country              VARCHAR(64),
    processing_time_ms   INT,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO fintech.transactions (
    transaction_id, customer_id, transaction_time, currency, channel,
    operation_type, status, country, processing_time_ms, created_at
) VALUES
    (1001, 501, '2026-01-15 10:30:00', 'RUB', 'mobile',   'payment',    'success',  'RU', 120, '2026-01-15 10:30:05'),
    (1002, 502, '2026-01-15 11:15:00', 'RUB', 'card',     'transfer',   'success',  'RU',  95, '2026-01-15 11:15:03'),
    (1003, 503, '2026-01-15 14:20:00', 'RUB', 'atm',      'withdrawal', 'success',  'RU', 200, '2026-01-15 14:20:10'),
    (1004, 504, '2026-01-15 16:45:00', 'USD', 'mobile',   'payment',    'declined', 'US',  80, '2026-01-15 16:45:02'),
    (1005, 505, '2026-01-16 09:00:00', 'RUB', 'internet', 'payment',    'success',  'RU', 150, '2026-01-16 09:00:04')
ON CONFLICT (transaction_id) DO NOTHING;

GRANT USAGE ON SCHEMA fintech TO trino;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA fintech TO trino;
ALTER DEFAULT PRIVILEGES IN SCHEMA fintech GRANT ALL ON TABLES TO trino;
