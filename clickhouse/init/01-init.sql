CREATE DATABASE IF NOT EXISTS fintech;

CREATE TABLE IF NOT EXISTS fintech.transaction_analytics
(
    transaction_id            UInt64,
    customer_id               UInt64,
    transaction_time          DateTime,
    amount                    Decimal(18, 2),
    customer_segment          String,
    region                    String,
    customer_risk_level       String,
    total_risk_score          Int32,
    transaction_risk_level    String,
    final_decision            String,
    fraud_detection_time_ms   Int32,
    triggered_rules_count     Int32,
    alerts_count              Int32,
    created_at                DateTime DEFAULT now()
)
ENGINE = MergeTree()
ORDER BY (transaction_time, transaction_id);

INSERT INTO fintech.transaction_analytics (transaction_id, customer_id, transaction_time, amount, customer_segment, region, customer_risk_level, total_risk_score, transaction_risk_level, final_decision, fraud_detection_time_ms, triggered_rules_count, alerts_count, created_at) VALUES (1001, 501, '2026-01-15 10:30:00', 15000.00, 'mass', 'Moscow', 'low', 15, 'low', 'allow', 45, 0, 0, '2026-01-15 10:30:05'), (1002, 502, '2026-01-15 11:15:00', 85000.00, 'premium', 'SPb', 'low', 22, 'low', 'allow', 38, 0, 0, '2026-01-15 11:15:03'), (1003, 503, '2026-01-15 14:20:00', 250000.00, 'business', 'Kazan', 'medium', 55, 'medium', 'review', 120, 2, 1, '2026-01-15 14:20:10'), (1004, 504, '2026-01-15 16:45:00', 5000.00, 'mass', 'unknown', 'high', 88, 'high', 'block', 200, 5, 3, '2026-01-15 16:45:02'), (1005, 505, '2026-01-16 09:00:00', 32000.00, 'premium', 'Moscow', 'low', 30, 'low', 'allow', 52, 1, 0, '2026-01-16 09:00:04');
