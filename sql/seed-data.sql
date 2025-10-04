-- sql/seed-data.sql
-- Seed fake data for crypto exchange database

-- ================================================================
-- SEED USERS (100 fake users)
-- ================================================================
INSERT INTO users (username, email, full_name, country_code, kyc_level, is_verified, risk_score)
SELECT
    'user_' || generate_series AS username,
    'user' || generate_series || '@cryptoexchange.com' AS email,
    'User ' || generate_series AS full_name,
    (ARRAY['US', 'GB', 'DE', 'FR', 'JP', 'KR', 'SG', 'AU', 'CA', 'BR'])[floor(random() * 10 + 1)] AS country_code,
    (ARRAY['basic', 'intermediate', 'advanced'])[floor(random() * 3 + 1)] AS kyc_level,
    random() > 0.3 AS is_verified,
    (random() * 100)::DECIMAL(5,2) AS risk_score
FROM generate_series(1, 100);

-- ================================================================
-- SEED MERCHANTS (20 merchants)
-- ================================================================
INSERT INTO merchants (merchant_name, merchant_category, country_code, risk_level)
VALUES
    ('Amazon Payments', 'e-commerce', 'US', 'low'),
    ('PayPal Crypto', 'payment_processor', 'US', 'low'),
    ('Steam Games', 'gaming', 'US', 'medium'),
    ('Booking.com', 'travel', 'NL', 'low'),
    ('Binance Exchange', 'crypto_exchange', 'MT', 'medium'),
    ('Coinbase Commerce', 'crypto_exchange', 'US', 'low'),
    ('Kraken Pay', 'crypto_exchange', 'US', 'low'),
    ('BitPay', 'payment_processor', 'US', 'medium'),
    ('Crypto.com Pay', 'payment_processor', 'SG', 'medium'),
    ('NFT Marketplace', 'nft', 'US', 'high'),
    ('DeFi Protocol', 'defi', 'CH', 'high'),
    ('Online Casino', 'gambling', 'CW', 'high'),
    ('VPN Service', 'privacy', 'PA', 'medium'),
    ('Web Hosting', 'services', 'US', 'low'),
    ('Cloud Storage', 'services', 'US', 'low'),
    ('Music Streaming', 'entertainment', 'SE', 'low'),
    ('Food Delivery', 'food', 'US', 'low'),
    ('Ride Sharing', 'transport', 'US', 'low'),
    ('Dark Web Market', 'illegal', 'XX', 'critical'),
    ('Mixer Service', 'privacy', 'XX', 'critical');

-- ================================================================
-- SEED WALLETS
-- ================================================================
INSERT INTO wallets (user_id, wallet_address, wallet_type, currency, balance)
SELECT
    user_id,
    '0x' || md5(random()::text || user_id::text || generate_series::text) AS wallet_address,
    (ARRAY['hot', 'cold'])[floor(random() * 2 + 1)] AS wallet_type,
    (ARRAY['BTC', 'ETH', 'USDT', 'BNB', 'SOL'])[floor(random() * 5 + 1)] AS currency,
    (random() * 10000)::DECIMAL(20,8) AS balance
FROM users
CROSS JOIN generate_series(1, (random() * 4 + 1)::int);

-- ================================================================
-- SEED NORMAL TRANSACTIONS (1000)
-- ================================================================
INSERT INTO transactions (
    transaction_hash,
    user_id,
    from_wallet_id,
    to_address,
    amount,
    currency,
    usd_amount,
    transaction_type,
    status,
    fee,
    network,
    confirmations,
    risk_score,
    is_flagged,
    ip_address,
    country_code,
    created_at
)
SELECT
    md5(random()::text || generate_series::text) AS transaction_hash,
    floor(random() * 100 + 1)::BIGINT AS user_id,
    floor(random() * 300 + 1)::BIGINT AS from_wallet_id,
    '0x' || md5(random()::text) AS to_address,
    (random() * 1000 + 0.001)::DECIMAL(20,8) AS amount,
    (ARRAY['BTC', 'ETH', 'USDT', 'BNB', 'SOL'])[floor(random() * 5 + 1)] AS currency,
    (random() * 50000 + 10)::DECIMAL(18,2) AS usd_amount,
    (ARRAY['deposit', 'withdrawal', 'transfer', 'payment', 'trade'])[floor(random() * 5 + 1)] AS transaction_type,
    (ARRAY['completed', 'pending', 'failed'])[floor(random() * 10 + 1)] AS status,
    (random() * 10)::DECIMAL(20,8) AS fee,
    (ARRAY['Bitcoin', 'Ethereum', 'BSC', 'Polygon', 'Solana'])[floor(random() * 5 + 1)] AS network,
    floor(random() * 100)::INT AS confirmations,
    (random() * 30)::DECIMAL(5,2) AS risk_score,
    FALSE AS is_flagged,
    ('192.168.' || floor(random() * 255) || '.' || floor(random() * 255))::INET AS ip_address,
    (ARRAY['US', 'GB', 'DE', 'FR', 'JP', 'KR', 'SG', 'AU', 'CA', 'BR'])[floor(random() * 10 + 1)] AS country_code,
    CURRENT_TIMESTAMP - (random() * INTERVAL '30 days') AS created_at
FROM generate_series(1, 1000);

-- ================================================================
-- SEED ANOMALOUS TRANSACTIONS (100)
-- ================================================================
INSERT INTO transactions (
    transaction_hash,
    user_id,
    from_wallet_id,
    to_address,
    amount,
    currency,
    usd_amount,
    transaction_type,
    status,
    fee,
    network,
    confirmations,
    risk_score,
    is_flagged,
    flag_reason,
    ip_address,
    country_code,
    created_at
)
SELECT
    md5(random()::text || 'large_' || generate_series::text) AS transaction_hash,
    floor(random() * 100 + 1)::BIGINT AS user_id,
    floor(random() * 300 + 1)::BIGINT AS from_wallet_id,
    '0x' || md5(random()::text) AS to_address,
    (random() * 950000 + 50000)::DECIMAL(20,8) AS amount,
    'BTC' AS currency,
    (random() * 50000000 + 2000000)::DECIMAL(18,2) AS usd_amount,
    'withdrawal' AS transaction_type,
    'completed' AS status,
    (random() * 100)::DECIMAL(20,8) AS fee,
    'Bitcoin' AS network,
    6 AS confirmations,
    (random() * 30 + 70)::DECIMAL(5,2) AS risk_score,
    TRUE AS is_flagged,
    'Large amount transaction' AS flag_reason,
    ('10.' || floor(random() * 255) || '.' || floor(random() * 255) || '.' || floor(random() * 255))::INET AS ip_address,
    (ARRAY['US', 'RU', 'CN', 'KP'])[floor(random() * 4 + 1)] AS country_code,
    CURRENT_TIMESTAMP - (random() * INTERVAL '7 days') AS created_at
FROM generate_series(1, 100);

-- ================================================================
-- STATISTICS
-- ================================================================
SELECT 
    'Users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'Wallets', COUNT(*) FROM wallets
UNION ALL
SELECT 'Transactions', COUNT(*) FROM transactions
UNION ALL
SELECT 'Merchants', COUNT(*) FROM merchants
ORDER BY table_name;