-- Homestead Operations Dashboard - Database Schema
-- Idempotent: safe to run on every boot

CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Categories for transaction classification
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed default categories (skip if already exist)
INSERT INTO categories (name) VALUES
    ('housing'), ('food'), ('transport'), ('utilities'),
    ('savings'), ('debt'), ('personal'), ('income'), ('other')
ON CONFLICT (name) DO NOTHING;

-- Financial accounts
CREATE TABLE IF NOT EXISTS accounts (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    institution TEXT,
    account_type TEXT NOT NULL CHECK (account_type IN ('checking', 'savings', 'credit', 'investment', 'cash')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transactions (dedup handled by replace-on-import strategy)
CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES accounts(id),
    date DATE NOT NULL,
    description TEXT NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    balance NUMERIC(12,2),
    category_id INTEGER REFERENCES categories(id),
    source TEXT DEFAULT 'manual',
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Point-in-time balance snapshots
-- source: 'manual' = user-entered anchor, 'calculated' = derived from anchor + transactions
CREATE TABLE IF NOT EXISTS balance_snapshots (
    id SERIAL PRIMARY KEY,
    account_id INTEGER NOT NULL REFERENCES accounts(id),
    snapshot_date DATE NOT NULL,
    balance NUMERIC(12,2) NOT NULL,
    source TEXT DEFAULT 'manual',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (account_id, snapshot_date, source)
);

-- Screenshot upload tracking
CREATE TABLE IF NOT EXISTS screenshots (
    id SERIAL PRIMARY KEY,
    filename TEXT NOT NULL,
    file_path TEXT NOT NULL,
    account_id INTEGER REFERENCES accounts(id),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'review')),
    ocr_text TEXT,
    error_message TEXT,
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ
);

-- Monthly budgets per category
CREATE TABLE IF NOT EXISTS budgets (
    id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL REFERENCES categories(id),
    month DATE NOT NULL,
    amount NUMERIC(12,2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (category_id, month)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date);
CREATE INDEX IF NOT EXISTS idx_transactions_account ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_desc_trgm ON transactions USING gin(description gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_transactions_source ON transactions(source);
CREATE INDEX IF NOT EXISTS idx_screenshots_status ON screenshots(status);
CREATE INDEX IF NOT EXISTS idx_balance_snapshots_account_date ON balance_snapshots(account_id, snapshot_date);

-- Add unique constraint for balance snapshot upsert (idempotent)
DO $$
BEGIN
    ALTER TABLE balance_snapshots ADD CONSTRAINT uq_balance_snapshots_account_date_source
        UNIQUE (account_id, snapshot_date, source);
EXCEPTION WHEN duplicate_table THEN
    NULL;
END $$;

-- Drop transaction dedup constraint (replaced by delete+reinsert strategy)
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_account_id_date_description_amount_key;

-- Grants for grafana (read-only)
GRANT USAGE ON SCHEMA public TO grafana;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO grafana;

-- Grants for homestead and metamageia (read-write)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO homestead;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO homestead;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO metamageia;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO metamageia;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO homestead;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO homestead;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO metamageia;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO metamageia;
