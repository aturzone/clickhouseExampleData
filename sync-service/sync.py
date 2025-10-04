"""
PostgreSQL to ClickHouse Sync Service - FIXED NULL handling
"""

import os
import time
import logging
import traceback
from datetime import datetime
from typing import List, Dict, Any

import psycopg2
from psycopg2.extras import RealDictCursor
import clickhouse_connect

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/app/logs/sync.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class PostgresClickHouseSync:
    """Sync data from PostgreSQL to ClickHouse"""
    
    def __init__(self):
        self.pg_config = {
            'host': os.getenv('PG_HOST', 'postgres-source'),
            'port': int(os.getenv('PG_PORT', 5432)),
            'database': os.getenv('PG_DATABASE', 'crypto_exchange'),
            'user': os.getenv('PG_USER', 'exchange_admin'),
            'password': os.getenv('PG_PASSWORD', 'Exchange2024Secure!')
        }
        
        self.ch_host = os.getenv('CH_HOST', 'clickhouse')
        self.ch_port = int(os.getenv('CH_PORT', 8123))
        self.ch_database = os.getenv('CH_DATABASE', 'crypto_analytics')
        self.ch_user = os.getenv('CH_USER', 'analytics_user')
        self.ch_password = os.getenv('CH_PASSWORD', 'ClickHouse2024!')
        
        self.sync_interval = int(os.getenv('SYNC_INTERVAL', 60))
        self.batch_size = int(os.getenv('BATCH_SIZE', 1000))
        
        self.last_sync_times = {}
        self.pg_conn = None
        self.ch_client = None
    
    def connect_postgres(self):
        try:
            self.pg_conn = psycopg2.connect(**self.pg_config)
            logger.info("✅ Connected to PostgreSQL")
        except Exception as e:
            logger.error(f"❌ PostgreSQL connection failed: {e}")
            raise
    
    def connect_clickhouse(self):
        try:
            self.ch_client = clickhouse_connect.get_client(
                host=self.ch_host,
                port=self.ch_port,
                username=self.ch_user,
                password=self.ch_password,
                database=self.ch_database
            )
            self.ch_client.command('SELECT 1')
            logger.info("✅ Connected to ClickHouse")
        except Exception as e:
            logger.error(f"❌ ClickHouse connection failed: {e}")
            raise
    
    def fetch_new_records(self, table_name: str, last_sync_time: datetime = None) -> List[Dict]:
        cursor = self.pg_conn.cursor(cursor_factory=RealDictCursor)
        try:
            if last_sync_time:
                query = f"SELECT * FROM {table_name} WHERE updated_at > %s ORDER BY updated_at LIMIT %s"
                cursor.execute(query, (last_sync_time, self.batch_size))
            else:
                query = f"SELECT * FROM {table_name} ORDER BY created_at LIMIT %s"
                cursor.execute(query, (self.batch_size,))
            return [dict(record) for record in cursor.fetchall()]
        except Exception as e:
            logger.error(f"❌ Fetch error from {table_name}: {e}")
            return []
        finally:
            cursor.close()
    
    def insert_to_clickhouse(self, table_name: str, records: List[Dict], columns: List[str]):
        if not records:
            return
        
        data_rows = [tuple(record[col] for col in columns) for record in records]
        
        try:
            self.ch_client.insert(
                f'{self.ch_database}.{table_name}',
                data_rows,
                column_names=columns
            )
            logger.info(f"  ✅ Inserted {len(records)} records into {table_name}")
        except Exception as e:
            logger.error(f"  ❌ Insert failed for {table_name}: {e}")
            raise
    
    def sync_users(self):
        table_name = 'users'
        logger.info(f"👥 Syncing {table_name}...")
        
        records = self.fetch_new_records(table_name, self.last_sync_times.get(table_name))
        if not records:
            logger.info(f"  ℹ️  No new records")
            return
        
        logger.info(f"  📦 Found {len(records)} records")
        transformed = [{
            'user_id': r['user_id'],
            'username': r['username'],
            'email': r['email'],
            'full_name': r['full_name'] or '',
            'country_code': r['country_code'] or 'XX',
            'kyc_level': r['kyc_level'] or 'basic',
            'is_verified': 1 if r['is_verified'] else 0,
            'risk_score': float(r['risk_score'] or 0),
            'registration_date': r['registration_date'],
            'last_login': r['last_login'],
            'created_at': r['created_at'],
            'updated_at': r['updated_at']
        } for r in records]
        
        self.insert_to_clickhouse(table_name, transformed, list(transformed[0].keys()))
        self.last_sync_times[table_name] = max(r['updated_at'] for r in records)
    
    def sync_wallets(self):
        table_name = 'wallets'
        logger.info(f"💼 Syncing {table_name}...")
        
        records = self.fetch_new_records(table_name, self.last_sync_times.get(table_name))
        if not records:
            logger.info(f"  ℹ️  No new records")
            return
        
        logger.info(f"  📦 Found {len(records)} records")
        transformed = [{
            'wallet_id': r['wallet_id'],
            'user_id': r['user_id'],
            'wallet_address': r['wallet_address'],
            'wallet_type': r['wallet_type'] or 'hot',
            'currency': r['currency'] or 'BTC',
            'balance': float(r['balance'] or 0),
            'is_active': 1 if r['is_active'] else 0,
            'created_at': r['created_at'],
            'updated_at': r['updated_at']
        } for r in records]
        
        self.insert_to_clickhouse(table_name, transformed, list(transformed[0].keys()))
        self.last_sync_times[table_name] = max(r['updated_at'] for r in records)
    
    def sync_merchants(self):
        table_name = 'merchants'
        logger.info(f"🏪 Syncing {table_name}...")
        
        cursor = self.pg_conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute(f"SELECT * FROM {table_name}")
        records = cursor.fetchall()
        cursor.close()
        
        if not records:
            logger.info(f"  ℹ️  No records")
            return
        
        logger.info(f"  📦 Found {len(records)} records")
        transformed = [{
            'merchant_id': r['merchant_id'],
            'merchant_name': r['merchant_name'],
            'merchant_category': r['merchant_category'] or 'general',
            'country_code': r['country_code'] or 'XX',
            'risk_level': r['risk_level'] or 'low',
            'is_active': 1 if r['is_active'] else 0,
            'created_at': r['created_at']
        } for r in records]
        
        self.insert_to_clickhouse(table_name, transformed, list(transformed[0].keys()))
    
    def sync_transactions(self):
        table_name = 'transactions'
        logger.info(f"📊 Syncing {table_name}...")
        
        records = self.fetch_new_records(table_name, self.last_sync_times.get(table_name))
        if not records:
            logger.info(f"  ℹ️  No new records")
            return
        
        logger.info(f"  📦 Found {len(records)} records")
        transformed = [{
            'transaction_id': r['transaction_id'],
            'transaction_hash': r['transaction_hash'],
            'user_id': r['user_id'] or 0,
            'from_wallet_id': r['from_wallet_id'] or 0,
            'to_wallet_id': r['to_wallet_id'] or 0,
            'to_address': r['to_address'] or '',
            'amount': float(r['amount'] or 0),
            'currency': r['currency'] or 'BTC',
            'usd_amount': float(r['usd_amount'] or 0),
            'fee': float(r['fee'] or 0),
            'transaction_type': r['transaction_type'] or 'unknown',
            'status': r['status'] or 'pending',
            'network': r['network'] or 'unknown',
            'confirmations': r['confirmations'] or 0,
            'block_number': r['block_number'],
            'risk_score': float(r['risk_score'] or 0),
            'is_flagged': 1 if r['is_flagged'] else 0,
            'flag_reason': r['flag_reason'] or '',
            'ip_address': str(r['ip_address']) if r['ip_address'] else '0.0.0.0',
            'device_id': r['device_id'] or '',
            'country_code': r['country_code'] or 'XX',
            'created_at': r['created_at'],
            'completed_at': r['completed_at'],
            'updated_at': r['updated_at']
        } for r in records]
        
        self.insert_to_clickhouse(table_name, transformed, list(transformed[0].keys()))
        self.last_sync_times[table_name] = max(r['updated_at'] for r in records)
    
    def sync_alerts(self):
        table_name = 'alerts'
        logger.info(f"🚨 Syncing {table_name}...")
        
        records = self.fetch_new_records(table_name, self.last_sync_times.get(table_name))
        if not records:
            logger.info(f"  ℹ️  No new records")
            return
        
        logger.info(f"  📦 Found {len(records)} records")
        transformed = [{
            'alert_id': r['alert_id'],
            'transaction_id': r['transaction_id'],
            'user_id': r['user_id'],
            'alert_type': r['alert_type'] or 'unknown',
            'severity': r['severity'] or 'low',
            'description': r['description'] or '',
            'status': r['status'] or 'open',
            'assigned_to': r['assigned_to'],
            'created_at': r['created_at'],
            'resolved_at': r['resolved_at']
        } for r in records]
        
        self.insert_to_clickhouse(table_name, transformed, list(transformed[0].keys()))
        self.last_sync_times[table_name] = max(r['created_at'] for r in records)
    
    def run_sync_cycle(self):
        logger.info("="*60)
        logger.info(f"🔄 Starting sync at {datetime.now()}")
        logger.info("="*60)
        
        try:
            self.sync_users()
            self.sync_wallets()
            self.sync_merchants()
            self.sync_transactions()
            self.sync_alerts()
            logger.info("✅ Sync completed")
        except Exception as e:
            logger.error(f"❌ Sync failed: {e}")
            logger.error(traceback.format_exc())
    
    def start(self):
        logger.info("🚀 Starting sync service...")
        self.connect_postgres()
        self.connect_clickhouse()
        logger.info(f"⏰ Interval: {self.sync_interval}s")
        
        while True:
            try:
                self.run_sync_cycle()
                time.sleep(self.sync_interval)
            except KeyboardInterrupt:
                logger.info("🛑 Stopped by user")
                break
            except Exception as e:
                logger.error(f"❌ Error: {e}")
                time.sleep(self.sync_interval)
        
        if self.pg_conn:
            self.pg_conn.close()
        if self.ch_client:
            self.ch_client.close()

if __name__ == "__main__":
    sync_service = PostgresClickHouseSync()
    sync_service.start()
