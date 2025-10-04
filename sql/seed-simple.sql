-- Simple seed that definitely works
BEGIN;

-- Users
INSERT INTO users (username, email, full_name, country_code, kyc_level, is_verified, risk_score) VALUES
('user_1', 'user1@crypto.com', 'Alice Johnson', 'US', 'advanced', true, 15.5),
('user_2', 'user2@crypto.com', 'Bob Smith', 'GB', 'basic', true, 25.0),
('user_3', 'user3@crypto.com', 'Charlie Brown', 'DE', 'intermediate', true, 35.2),
('user_4', 'user4@crypto.com', 'Diana Prince', 'FR', 'advanced', true, 12.8),
('user_5', 'user5@crypto.com', 'Eve Adams', 'JP', 'basic', false, 45.9);

-- Merchants
INSERT INTO merchants (merchant_name, merchant_category, country_code, risk_level) VALUES
('Amazon Pay', 'e-commerce', 'US', 'low'),
('Binance', 'crypto_exchange', 'MT', 'medium'),
('Coinbase', 'crypto_exchange', 'US', 'low'),
('Steam', 'gaming', 'US', 'medium'),
('Suspicious Shop', 'unknown', 'XX', 'high');

-- Wallets
INSERT INTO wallets (user_id, wallet_address, wallet_type, currency, balance) VALUES
(1, '0xabc123def456', 'hot', 'BTC', 1.5),
(1, '0xdef456ghi789', 'cold', 'ETH', 25.0),
(2, '0xghi789jkl012', 'hot', 'USDT', 10000.0),
(3, '0xjkl012mno345', 'hot', 'BTC', 0.5),
(4, '0xmno345pqr678', 'cold', 'ETH', 50.0),
(5, '0xpqr678stu901', 'hot', 'BNB', 100.0);

-- Normal Transactions (10)
INSERT INTO transactions (transaction_hash, user_id, from_wallet_id, to_address, amount, currency, usd_amount, transaction_type, status, fee, network, confirmations, risk_score, is_flagged) VALUES
('hash001', 1, 1, '0xdest001', 0.1, 'BTC', 5000.00, 'withdrawal', 'completed', 0.001, 'Bitcoin', 6, 15.5, false),
('hash002', 2, 3, '0xdest002', 500.0, 'USDT', 500.00, 'transfer', 'completed', 1.0, 'Ethereum', 12, 20.0, false),
('hash003', 1, 2, '0xdest003', 2.0, 'ETH', 6000.00, 'payment', 'completed', 0.01, 'Ethereum', 12, 18.2, false),
('hash004', 3, 4, '0xdest004', 0.05, 'BTC', 2500.00, 'deposit', 'completed', 0.0005, 'Bitcoin', 3, 22.5, false),
('hash005', 4, 5, '0xdest005', 5.0, 'ETH', 15000.00, 'transfer', 'completed', 0.02, 'Ethereum', 6, 16.8, false),
('hash006', 5, 6, '0xdest006', 10.0, 'BNB', 4000.00, 'payment', 'completed', 0.1, 'BSC', 1, 25.0, false),
('hash007', 2, 3, '0xdest007', 1000.0, 'USDT', 1000.00, 'withdrawal', 'completed', 2.0, 'Ethereum', 12, 19.5, false),
('hash008', 1, 1, '0xdest008', 0.2, 'BTC', 10000.00, 'trade', 'completed', 0.002, 'Bitcoin', 6, 17.3, false),
('hash009', 3, 4, '0xdest009', 0.1, 'BTC', 5000.00, 'payment', 'pending', 0.001, 'Bitcoin', 2, 21.0, false),
('hash010', 4, 5, '0xdest010', 3.0, 'ETH', 9000.00, 'transfer', 'completed', 0.015, 'Ethereum', 12, 14.5, false);

-- Suspicious Transactions (5)
INSERT INTO transactions (transaction_hash, user_id, from_wallet_id, to_address, amount, currency, usd_amount, transaction_type, status, fee, network, confirmations, risk_score, is_flagged, flag_reason) VALUES
('hash_sus01', 2, 3, '0xdanger01', 5000.0, 'USDT', 5000.00, 'withdrawal', 'completed', 5.0, 'Ethereum', 6, 85.5, true, 'Large amount withdrawal'),
('hash_sus02', 1, 1, '0xdanger02', 10.0, 'BTC', 500000.00, 'withdrawal', 'completed', 0.01, 'Bitcoin', 6, 92.3, true, 'Extremely large transaction'),
('hash_sus03', 5, 6, '0xdanger03', 50.0, 'BNB', 20000.00, 'transfer', 'completed', 0.5, 'BSC', 1, 78.9, true, 'High risk country'),
('hash_sus04', 3, 4, '0xdanger04', 5.0, 'BTC', 250000.00, 'payment', 'completed', 0.005, 'Bitcoin', 6, 88.2, true, 'Suspicious pattern'),
('hash_sus05', 4, 5, '0xdanger05', 100.0, 'ETH', 300000.00, 'withdrawal', 'completed', 0.1, 'Ethereum', 12, 95.7, true, 'Multiple red flags');

-- Alerts for suspicious transactions
INSERT INTO alerts (transaction_id, user_id, alert_type, severity, description, status) VALUES
(11, 2, 'large_transaction', 'high', 'Large USDT withdrawal detected', 'open'),
(12, 1, 'large_transaction', 'critical', 'Extremely large BTC transaction', 'investigating'),
(13, 5, 'high_risk_country', 'medium', 'Transaction from high-risk location', 'open'),
(14, 3, 'suspicious_pattern', 'high', 'Unusual transaction pattern detected', 'open'),
(15, 4, 'multiple_flags', 'critical', 'Multiple risk indicators present', 'investigating');

COMMIT;

-- Show results
SELECT 'Data inserted successfully!' as status;
SELECT 'Users' as table_name, COUNT(*) as count FROM users
UNION ALL SELECT 'Wallets', COUNT(*) FROM wallets
UNION ALL SELECT 'Transactions', COUNT(*) FROM transactions
UNION ALL SELECT 'Merchants', COUNT(*) FROM merchants
UNION ALL SELECT 'Alerts', COUNT(*) FROM alerts;
