-- Quick seed for testing
INSERT INTO users (username, email, full_name, country_code, kyc_level, is_verified, risk_score)
VALUES 
  ('user_1', 'user1@test.com', 'Test User 1', 'US', 'basic', true, 25.5),
  ('user_2', 'user2@test.com', 'Test User 2', 'GB', 'advanced', true, 15.2);

INSERT INTO wallets (user_id, wallet_address, wallet_type, currency, balance)
VALUES
  (1, '0xabc123', 'hot', 'BTC', 1.5),
  (1, '0xdef456', 'cold', 'ETH', 10.0),
  (2, '0xghi789', 'hot', 'USDT', 5000.0);

INSERT INTO transactions (transaction_hash, user_id, from_wallet_id, to_address, amount, currency, usd_amount, transaction_type, status, fee, network, confirmations, risk_score, is_flagged)
VALUES
  (md5(random()::text), 1, 1, '0xdest1', 0.5, 'BTC', 25000, 'withdrawal', 'completed', 0.001, 'Bitcoin', 6, 30.5, false),
  (md5(random()::text), 1, 2, '0xdest2', 2.0, 'ETH', 6000, 'transfer', 'completed', 0.01, 'Ethereum', 12, 20.0, false),
  (md5(random()::text), 2, 3, '0xdest3', 1000, 'USDT', 1000, 'payment', 'completed', 1.0, 'Ethereum', 6, 85.5, true);

SELECT 'Quick seed completed!' as status;
