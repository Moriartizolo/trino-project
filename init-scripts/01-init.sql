-- Пользователь для Iceberg JDBC catalog
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'trino') THEN
        CREATE USER trino WITH PASSWORD 'trino_pass';
    END IF;
END $$;

GRANT ALL PRIVILEGES ON DATABASE iceberg_meta TO trino;
GRANT ALL PRIVILEGES ON SCHEMA public TO trino;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO trino;

-- Демо-таблица для проверки PostgreSQL-каталога в Trino
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
