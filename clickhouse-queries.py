#!/usr/bin/env python3
"""
ClickHouse Analytics Queries for Crypto Anomaly Detection
Ready for ML Feature Engineering
"""

import clickhouse_connect
from datetime import datetime
import pandas as pd

client = clickhouse_connect.get_client(
    host='localhost',
    port=8123,
    username='analytics_user',
    password='ClickHouse2024!',
    database='crypto_analytics'
)

def print_section(title):
    print("\n" + "="*60)
    print(f"  {title}")
    print("="*60)

def query_1_high_risk():
    print_section("High Risk Transactions (Score > 70)")
    df = client.query_df("""
        SELECT transaction_id, user_id, currency, usd_amount, 
               risk_score, flag_reason, created_at
        FROM transactions
        WHERE risk_score > 70
        ORDER BY risk_score DESC LIMIT 10
    """)
    if len(df) > 0:
        print(df.to_string(index=False))
        print(f"\nTotal: {len(df)}")
    else:
        print("No data")

def query_2_user_stats():
    print_section("User Statistics (for ML features)")
    df = client.query_df("""
        SELECT user_id, COUNT(*) as total_tx,
               round(AVG(usd_amount), 2) as avg_amount,
               round(stddevPop(usd_amount), 2) as std_amount,
               round(MAX(usd_amount), 2) as max_amount,
               SUM(CAST(is_flagged AS UInt32)) as flagged_count,
               round(AVG(risk_score), 2) as avg_risk_score
        FROM transactions
        GROUP BY user_id
        ORDER BY total_tx DESC LIMIT 10
    """)
    if len(df) > 0:
        print(df.to_string(index=False))
    else:
        print("No data")

def query_3_large_amounts():
    print_section("Large Transactions (> $1M)")
    df = client.query_df("""
        SELECT transaction_id, user_id, currency, usd_amount,
               transaction_type, created_at
        FROM transactions
        WHERE usd_amount > 1000000
        ORDER BY usd_amount DESC LIMIT 10
    """)
    if len(df) > 0:
        print(df.to_string(index=False))
    else:
        print("No large transactions")

def query_4_by_country():
    print_section("Statistics by Country")
    df = client.query_df("""
        SELECT country_code, COUNT(*) as tx_count,
               round(SUM(usd_amount), 2) as total_volume,
               round(AVG(risk_score), 2) as avg_risk,
               SUM(CAST(is_flagged AS UInt32)) as flagged_count
        FROM transactions
        GROUP BY country_code
        ORDER BY total_volume DESC LIMIT 10
    """)
    if len(df) > 0:
        print(df.to_string(index=False))
    else:
        print("No data")

def query_5_summary():
    print_section("Overall Summary")
    df = client.query_df("""
        SELECT COUNT(*) as total_tx,
               COUNT(DISTINCT user_id) as unique_users,
               round(SUM(usd_amount), 2) as total_volume,
               round(AVG(usd_amount), 2) as avg_amount,
               SUM(CAST(is_flagged AS UInt32)) as flagged_tx,
               round(AVG(risk_score), 2) as avg_risk
        FROM transactions
    """)
    if len(df) > 0:
        print(df.to_string(index=False))
    else:
        print("No data")

def main():
    print("\n" + "="*60)
    print("  ClickHouse Anomaly Detection Queries")
    print(f"  Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*60)
    
    try:
        query_5_summary()
        query_1_high_risk()
        query_2_user_stats()
        query_3_large_amounts()
        query_4_by_country()
        
        print("\n" + "="*60)
        print("  All queries executed successfully!")
        print("="*60 + "\n")
        
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
    finally:
        client.close()

if __name__ == "__main__":
    main()
