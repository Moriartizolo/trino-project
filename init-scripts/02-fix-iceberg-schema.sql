-- Миграция: заменяем устаревшие таблицы метаданных на схему Iceberg JDBC catalog V1
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'trino') THEN
        CREATE USER trino WITH PASSWORD 'trino_pass';
    END IF;
END $$;

GRANT ALL PRIVILEGES ON DATABASE iceberg_meta TO trino;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'iceberg_namespace_properties'
          AND column_name = 'properties'
    ) THEN
        ALTER TABLE iceberg_namespace_properties RENAME TO iceberg_namespace_properties_legacy;
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS iceberg_namespace_properties (
    catalog_name VARCHAR(255) NOT NULL,
    namespace VARCHAR(255) NOT NULL,
    property_key VARCHAR(255),
    property_value VARCHAR(1000),
    PRIMARY KEY (catalog_name, namespace, property_key)
);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'iceberg_tables'
          AND column_name = 'table_uuid'
    ) THEN
        ALTER TABLE iceberg_tables RENAME TO iceberg_tables_legacy;
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS iceberg_tables (
    catalog_name VARCHAR(255) NOT NULL,
    table_namespace VARCHAR(255) NOT NULL,
    table_name VARCHAR(255) NOT NULL,
    metadata_location VARCHAR(1000),
    previous_metadata_location VARCHAR(1000),
    PRIMARY KEY (catalog_name, table_namespace, table_name)
);

DROP TABLE IF EXISTS iceberg_namespace_properties_legacy;
DROP TABLE IF EXISTS iceberg_tables_legacy;
DROP TABLE IF EXISTS table_history;

CREATE TABLE IF NOT EXISTS demo_users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO demo_users (name, email) VALUES
    ('Alice', 'alice@example.com'),
    ('Bob', 'bob@example.com')
ON CONFLICT (email) DO NOTHING;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO trino;
GRANT ALL PRIVILEGES ON SCHEMA public TO trino;
