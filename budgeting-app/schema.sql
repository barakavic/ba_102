-- Refactored Schema for PostgreSQL
-- Aligned with Frontend Models and Feature-First Architecture

DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS plans;

CREATE TABLE plans (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(50) DEFAULT 'ACTIVE',
    limit_amount DOUBLE PRECISION DEFAULT 0.0,
    plan_type VARCHAR(50) DEFAULT 'monthly',
    client_id VARCHAR(255) UNIQUE
);

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    limit_amount DOUBLE PRECISION DEFAULT 0.0,
    icon VARCHAR(255),
    color VARCHAR(50),
    parent_id BIGINT,
    client_id VARCHAR(255) UNIQUE
);

CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    amount DOUBLE PRECISION NOT NULL,
    description TEXT,
    date TIMESTAMP NOT NULL,
    type VARCHAR(50) DEFAULT 'outbound',
    vendor VARCHAR(255),
    mpesa_reference VARCHAR(255) UNIQUE,
    balance DOUBLE PRECISION,
    raw_sms_message TEXT,
    client_id VARCHAR(255) UNIQUE,
    plan_id BIGINT REFERENCES plans(id),
    category_id BIGINT REFERENCES categories(id)
);
