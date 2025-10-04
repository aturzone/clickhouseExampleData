-- sql/init-source-db.sql
-- Initialize PostgreSQL database for crypto exchange transactions
-- This represents the OLTP (transactional) database

-- ================================================================
-- USERS TABLE
-- ================================================================
CREATE TABLE IF NOT EXISTS users (
    user_id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    full_name VARCHAR(100),
    country_code CHAR(2),
    kyc_level VARCHAR(20) DEFAULT 'basic',
    is_verified BOOLEAN DEFAULT FALSE,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    risk_score DECIMAL(5,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_country ON users(country_code);
CREATE INDEX idx_users_kyc_level ON users(kyc_level);
CREATE INDEX idx_users_risk_score ON users(risk_score);

-- ================================================================
-- WALLETS TABLE
-- ================================================================
CREATE TABLE IF NOT EXISTS wallets (
    wallet_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
    wallet_address VARCHAR(100) UNIQUE NOT NULL,
    wallet_type VARCHAR(20) DEFAULT 'hot',
    currency VARCHAR(10) NOT NULL,
    balance DECIMAL(20,8) DEFAULT 0.00000000,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_wallets_user ON wallets(user_id);
CREATE INDEX idx_wallets_currency ON wallets(currency);
CREATE INDEX idx_wallets_address ON wallets(wallet_address);

-- ================================================================
-- TRANSACTIONS TABLE (Main table for anomaly detection)
-- ================================================================
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    transaction_hash VARCHAR(100) UNIQUE NOT NULL,
    user_id BIGINT REFERENCES users(user_id),
    
    -- Transaction Details
    from_wallet_id BIGINT REFERENCES wallets(wallet_id),
    to_wallet_id BIGINT,
    to_address VARCHAR(100),
    
    -- Financial Details
    amount DECIMAL(20,8) NOT NULL,
    currency VARCHAR(10) NOT NULL,
    usd_amount DECIMAL(18,2),
    
    -- Transaction Metadata
    transaction_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    fee DECIMAL(20,8) DEFAULT 0.00000000,
    
    -- Network Details
    network VARCHAR(20),
    confirmations INT DEFAULT 0,
    block_number BIGINT,
    
    -- Risk & Compliance
    risk_score DECIMAL(5,2) DEFAULT 0.00,
    is_flagged BOOLEAN DEFAULT FALSE,
    flag_reason TEXT,
    reviewed_by BIGINT,
    reviewed_at TIMESTAMP,
    
    -- Device & Location
    ip_address INET,
    device_id VARCHAR(100),
    user_agent TEXT,
    country_code CHAR(2),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tx_user ON transactions(user_id);
CREATE INDEX idx_tx_created_at ON transactions(created_at);
CREATE INDEX idx_tx_status ON transactions(status);
CREATE INDEX idx_tx_currency ON transactions(currency);
CREATE INDEX idx_tx_type ON transactions(transaction_type);
CREATE INDEX idx_tx_flagged ON transactions(is_flagged);
CREATE INDEX idx_tx_risk_score ON transactions(risk_score);
CREATE INDEX idx_tx_amount ON transactions(amount);
CREATE INDEX idx_tx_hash ON transactions(transaction_hash);

-- ================================================================
-- MERCHANTS TABLE (for payment transactions)
-- ================================================================
CREATE TABLE IF NOT EXISTS merchants (
    merchant_id BIGSERIAL PRIMARY KEY,
    merchant_name VARCHAR(100) NOT NULL,
    merchant_category VARCHAR(50),
    country_code CHAR(2),
    risk_level VARCHAR(20) DEFAULT 'low',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_merchants_category ON merchants(merchant_category);
CREATE INDEX idx_merchants_risk ON merchants(risk_level);

-- ================================================================
-- MERCHANT_TRANSACTIONS TABLE
-- ================================================================
CREATE TABLE IF NOT EXISTS merchant_transactions (
    id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT REFERENCES transactions(transaction_id),
    merchant_id BIGINT REFERENCES merchants(merchant_id),
    payment_method VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_merchant_tx_transaction ON merchant_transactions(transaction_id);
CREATE INDEX idx_merchant_tx_merchant ON merchant_transactions(merchant_id);

-- ================================================================
-- ALERTS TABLE (for flagged transactions)
-- ================================================================
CREATE TABLE IF NOT EXISTS alerts (
    alert_id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT REFERENCES transactions(transaction_id),
    user_id BIGINT REFERENCES users(user_id),
    alert_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) DEFAULT 'medium',
    description TEXT,
    status VARCHAR(20) DEFAULT 'open',
    assigned_to BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP
);

CREATE INDEX idx_alerts_transaction ON alerts(transaction_id);
CREATE INDEX idx_alerts_user ON alerts(user_id);
CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_severity ON alerts(severity);

-- ================================================================
-- AUDIT LOG TABLE
-- ================================================================
CREATE TABLE IF NOT EXISTS audit_log (
    log_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(50),
    record_id BIGINT,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_audit_created_at ON audit_log(created_at);
CREATE INDEX idx_audit_action ON audit_log(action);

-- ================================================================
-- TRIGGER FOR UPDATED_AT
-- ================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wallets_updated_at
    BEFORE UPDATE ON wallets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ================================================================
-- SUCCESS MESSAGE
-- ================================================================
SELECT 'PostgreSQL Exchange Database initialized successfully!' as status;