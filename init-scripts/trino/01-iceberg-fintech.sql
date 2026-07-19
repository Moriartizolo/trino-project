CREATE SCHEMA IF NOT EXISTS iceberg.fintech;

CREATE TABLE IF NOT EXISTS iceberg.fintech.transaction_facts (
    transaction_id            BIGINT,
    customer_id               BIGINT,
    transaction_time          TIMESTAMP(6),
    amount                    DECIMAL(18, 2),
    currency                  VARCHAR(3),
    channel                   VARCHAR(32),
    operation_type            VARCHAR(32),
    status                    VARCHAR(16),
    country                   VARCHAR(64),
    processing_time_ms        INTEGER,
    customer_segment          VARCHAR(16),
    region                    VARCHAR(64),
    customer_risk_level       VARCHAR(16),
    total_risk_score          INTEGER,
    transaction_risk_level    VARCHAR(16),
    final_decision            VARCHAR(16),
    fraud_detection_time_ms   INTEGER,
    triggered_rules_count     INTEGER,
    alerts_count              INTEGER,
    created_at                TIMESTAMP(6)
);

INSERT INTO iceberg.fintech.transaction_facts VALUES
    (1001, 501, TIMESTAMP '2026-01-15 10:30:00', 15000.00, 'RUB', 'mobile',   'payment',    'success',  'RU', 120, 'mass',     'Moscow',  'low',    15, 'low',    'allow',  45,  0, 0, TIMESTAMP '2026-01-15 10:30:05'),
    (1002, 502, TIMESTAMP '2026-01-15 11:15:00', 85000.00, 'RUB', 'card',     'transfer',   'success',  'RU',  95, 'premium',  'SPb',     'low',    22, 'low',    'allow',  38,  0, 0, TIMESTAMP '2026-01-15 11:15:03'),
    (1003, 503, TIMESTAMP '2026-01-15 14:20:00', 250000.00, 'RUB', 'atm',      'withdrawal', 'success',  'RU', 200, 'business', 'Kazan',   'medium', 55, 'medium', 'review', 120, 2, 1, TIMESTAMP '2026-01-15 14:20:10'),
    (1004, 504, TIMESTAMP '2026-01-15 16:45:00', 5000.00,  'USD', 'mobile',   'payment',    'declined', 'US',  80, 'mass',     'unknown', 'high',   88, 'high',   'block',  200, 5, 3, TIMESTAMP '2026-01-15 16:45:02'),
    (1005, 505, TIMESTAMP '2026-01-16 09:00:00', 32000.00, 'RUB', 'internet', 'payment',    'success',  'RU', 150, 'premium',  'Moscow',  'low',    30, 'low',    'allow',  52,  1, 0, TIMESTAMP '2026-01-16 09:00:04');
