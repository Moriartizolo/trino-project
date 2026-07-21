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
