CREATE TABLE IF NOT EXISTS analytics.orders
(
    order_id UInt64,
    customer String,
    amount Float64,
    created_at DateTime DEFAULT now()
)
ENGINE = MergeTree()
ORDER BY (created_at, order_id);
