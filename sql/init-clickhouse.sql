CREATE TABLE IF NOT EXISTS crypto_analytics.users (
    user_id UInt64,
    username String,
    email String,
    full_name String,
    country_code LowCardinality(FixedString(2)),
    kyc_level LowCardinality(String),
    is_verified UInt8,
    risk_score Float32,
    registration_date DateTime64(3, 'UTC'),
    last_login Nullable(DateTime64(3, 'UTC')),
    created_at DateTime64(3, 'UTC'),
    updated_at DateTime64(3, 'UTC')
)
ENGINE = ReplacingMergeTree(updated_at)
ORDER BY user_id;

CREATE TABLE IF NOT EXISTS crypto_analytics.wallets (
    wallet_id UInt64,
    user_id UInt64,
    wallet_address String,
    wallet_type LowCardinality(String),
    currency LowCardinality(String),
    balance Decimal(20, 8),
    is_active UInt8,
    created_at DateTime64(3, 'UTC'),
    updated_at DateTime64(3, 'UTC')
)
ENGINE = ReplacingMergeTree(updated_at)
ORDER BY (user_id, wallet_id);

CREATE TABLE IF NOT EXISTS crypto_analytics.merchants (
    merchant_id UInt64,
    merchant_name String,
    merchant_category LowCardinality(String),
    country_code LowCardinality(FixedString(2)),
    risk_level LowCardinality(String),
    is_active UInt8,
    created_at DateTime64(3, 'UTC')
)
ENGINE = ReplacingMergeTree(created_at)
ORDER BY merchant_id;

CREATE TABLE IF NOT EXISTS crypto_analytics.transactions (
    transaction_id UInt64,
    transaction_hash String,
    user_id UInt64,
    from_wallet_id UInt64,
    to_wallet_id UInt64,
    to_address String,
    amount Decimal(20, 8),
    currency LowCardinality(String),
    usd_amount Decimal(18, 2),
    fee Decimal(20, 8),
    transaction_type LowCardinality(String),
    status LowCardinality(String),
    network LowCardinality(String),
    confirmations UInt16,
    block_number Nullable(UInt64),
    risk_score Float32,
    is_flagged UInt8,
    flag_reason String,
    ip_address IPv4,
    device_id String,
    country_code LowCardinality(FixedString(2)),
    created_at DateTime64(3, 'UTC'),
    completed_at Nullable(DateTime64(3, 'UTC')),
    updated_at DateTime64(3, 'UTC')
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(created_at)
ORDER BY (user_id, created_at, transaction_id);

CREATE TABLE IF NOT EXISTS crypto_analytics.alerts (
    alert_id UInt64,
    transaction_id UInt64,
    user_id UInt64,
    alert_type LowCardinality(String),
    severity LowCardinality(String),
    description String,
    status LowCardinality(String),
    assigned_to Nullable(UInt64),
    created_at DateTime64(3, 'UTC'),
    resolved_at Nullable(DateTime64(3, 'UTC'))
)
ENGINE = MergeTree()
ORDER BY (severity, status, created_at, alert_id);
