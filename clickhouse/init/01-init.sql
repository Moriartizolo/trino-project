CREATE DATABASE IF NOT EXISTS analytics;

CREATE TABLE IF NOT EXISTS analytics.events
(
    event_id UInt64,
    user_name String,
    event_type String,
    created_at DateTime
)
ENGINE = MergeTree()
ORDER BY (created_at, event_id);

INSERT INTO analytics.events (event_id, user_name, event_type, created_at) VALUES (1, 'Alice', 'page_view', now()), (2, 'Bob', 'purchase', now()), (3, 'Charlie', 'click', now());
