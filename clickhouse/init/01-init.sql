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

INSERT INTO fintech.transaction_analytics (
    transaction_id, customer_id, transaction_time, amount, customer_segment, region,
    customer_risk_level, total_risk_score, transaction_risk_level, final_decision,
    fraud_detection_time_ms, triggered_rules_count, alerts_count, created_at
)
SELECT
    transaction_id, customer_id, transaction_time, amount, customer_segment, region,
    customer_risk_level, total_risk_score, transaction_risk_level, final_decision,
    fraud_detection_time_ms, triggered_rules_count, alerts_count, created_at
FROM (
    SELECT 1001 AS transaction_id, 501 AS customer_id, toDateTime('2026-01-15 10:30:00') AS transaction_time, toDecimal64(15000.00, 2) AS amount, 'mass' AS customer_segment, 'Moscow' AS region, 'low' AS customer_risk_level, 15 AS total_risk_score, 'low' AS transaction_risk_level, 'allow' AS final_decision, 45 AS fraud_detection_time_ms, 0 AS triggered_rules_count, 0 AS alerts_count, toDateTime('2026-01-15 10:30:05') AS created_at
    UNION ALL SELECT 1002, 502, toDateTime('2026-01-15 11:15:00'), toDecimal64(85000.00, 2), 'premium', 'SPb', 'low', 22, 'low', 'allow', 38, 0, 0, toDateTime('2026-01-15 11:15:03')
    UNION ALL SELECT 1003, 503, toDateTime('2026-01-15 14:20:00'), toDecimal64(250000.00, 2), 'business', 'Kazan', 'medium', 55, 'medium', 'review', 120, 2, 1, toDateTime('2026-01-15 14:20:10')
    UNION ALL SELECT 1004, 504, toDateTime('2026-01-15 16:45:00'), toDecimal64(5000.00, 2), 'mass', 'unknown', 'high', 88, 'high', 'block', 200, 5, 3, toDateTime('2026-01-15 16:45:02')
    UNION ALL SELECT 1005, 505, toDateTime('2026-01-16 09:00:00'), toDecimal64(32000.00, 2), 'premium', 'Moscow', 'low', 30, 'low', 'allow', 52, 1, 0, toDateTime('2026-01-16 09:00:04')
) AS seed
WHERE (SELECT count() FROM fintech.transaction_analytics) = 0;
