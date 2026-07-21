INSERT INTO iceberg.fintech.transaction_facts
SELECT *
FROM (
    VALUES
        (BIGINT '1001', BIGINT '501', TIMESTAMP '2026-01-15 10:30:00', DECIMAL '15000.00', VARCHAR 'RUB', VARCHAR 'mobile',   VARCHAR 'payment',    VARCHAR 'success',  VARCHAR 'RU', INTEGER '120', VARCHAR 'mass',     VARCHAR 'Moscow',  VARCHAR 'low',    INTEGER '15', VARCHAR 'low',    VARCHAR 'allow',  INTEGER '45',  INTEGER '0', INTEGER '0', TIMESTAMP '2026-01-15 10:30:05'),
        (BIGINT '1002', BIGINT '502', TIMESTAMP '2026-01-15 11:15:00', DECIMAL '85000.00', VARCHAR 'RUB', VARCHAR 'card',     VARCHAR 'transfer',   VARCHAR 'success',  VARCHAR 'RU', INTEGER '95',  VARCHAR 'premium',  VARCHAR 'SPb',     VARCHAR 'low',    INTEGER '22', VARCHAR 'low',    VARCHAR 'allow',  INTEGER '38',  INTEGER '0', INTEGER '0', TIMESTAMP '2026-01-15 11:15:03'),
        (BIGINT '1003', BIGINT '503', TIMESTAMP '2026-01-15 14:20:00', DECIMAL '250000.00', VARCHAR 'RUB', VARCHAR 'atm',      VARCHAR 'withdrawal', VARCHAR 'success',  VARCHAR 'RU', INTEGER '200', VARCHAR 'business', VARCHAR 'Kazan',   VARCHAR 'medium', INTEGER '55', VARCHAR 'medium', VARCHAR 'review', INTEGER '120', INTEGER '2', INTEGER '1', TIMESTAMP '2026-01-15 14:20:10'),
        (BIGINT '1004', BIGINT '504', TIMESTAMP '2026-01-15 16:45:00', DECIMAL '5000.00',  VARCHAR 'USD', VARCHAR 'mobile',   VARCHAR 'payment',    VARCHAR 'declined', VARCHAR 'US', INTEGER '80',  VARCHAR 'mass',     VARCHAR 'unknown', VARCHAR 'high',   INTEGER '88', VARCHAR 'high',   VARCHAR 'block',  INTEGER '200', INTEGER '5', INTEGER '3', TIMESTAMP '2026-01-15 16:45:02'),
        (BIGINT '1005', BIGINT '505', TIMESTAMP '2026-01-16 09:00:00', DECIMAL '32000.00', VARCHAR 'RUB', VARCHAR 'internet', VARCHAR 'payment',    VARCHAR 'success',  VARCHAR 'RU', INTEGER '150', VARCHAR 'premium',  VARCHAR 'Moscow',  VARCHAR 'low',    INTEGER '30', VARCHAR 'low',    VARCHAR 'allow',  INTEGER '52',  INTEGER '1', INTEGER '0', TIMESTAMP '2026-01-16 09:00:04')
) AS seed(
    transaction_id, customer_id, transaction_time, amount, currency, channel,
    operation_type, status, country, processing_time_ms, customer_segment, region,
    customer_risk_level, total_risk_score, transaction_risk_level, final_decision,
    fraud_detection_time_ms, triggered_rules_count, alerts_count, created_at
)
WHERE NOT EXISTS (
    SELECT 1 FROM iceberg.fintech.transaction_facts WHERE transaction_id = BIGINT '1001'
);
