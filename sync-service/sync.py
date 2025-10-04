"""
PostgreSQL to ClickHouse Sync Service
این سرویس به صورت خودکار داده‌ها رو از PostgreSQL به ClickHouse منتقل میکنه
"""

import os
import time
import logging
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
        # PostgreSQL connection
        self.pg_config = {
            'host': os.getenv('PG_HOST', 'postgres-source'),
            'port': int(os.getenv('PG_PORT', 5432)),
            'database': os.getenv('PG_DATABASE', 'crypto_exchange'),
            'user': os.getenv('PG_USER', 'exchange_admin'),
            'password': os.getenv('PG_PASSWORD', 'Exchange2024Secure!')
        }
        
        # ClickHouse connection
        self.ch_host = os.getenv('CH_HOST', 'clickhouse')
        self.ch_port = int(os.getenv('CH_PORT', 8123))
        self.ch_database = os.getenv('CH_DATABASE', 'crypto_analytics')
        self.ch_user = os.getenv('CH_USER', 'analytics_user')
        self.ch_password = os.getenv('CH_PASSWORD', 'ClickHouse2024!')
        
        # Sync configuration
        self.sync_interval = int(os.getenv('SYNC_INTERVAL', 60))
        self.batch_size = int(os.getenv('BATCH_SIZE', 1000))
        
        # Track last sync timestamps
        self.last_sync_times = {}
        
        self.pg_conn = None
        self.ch_client = None
    
    def connect_postgres(self):
        """Connect to PostgreSQL"""
        try:
            self.pg_conn = psycopg2.connect(**self.pg_config)
            logger.info("✅ Connected to PostgreSQL successfully")
        except Exception as e:
            logger.error(f"❌ Failed to connect to PostgreSQL: {e}")
            raise
    
    def connect_clickhouse(self):
        """Connect to ClickHouse"""
        try:
            self.ch_client = clickhouse_connect.get_client(
                host=self.ch_host,
                port=8123,  # HTTP port
                username=self.ch_user,
                password=self.ch_password,
                database=self.ch_database
            )
            logger.info("✅ Connected to ClickHouse successfully")
        except Exception as e:
            logger.error(f"❌ Failed to connect to ClickHouse: {e}")
            raise
    
    def fetch_new_records(self, table_name: str, last_sync_time: datetime = None) -> List[Dict]:
        """Fetch new/updated records from PostgreSQL"""
        cursor = self.pg_conn.cursor(cursor_factory=RealDictCursor)
        
        try:
            if last_sync_time:
                query = f"""
                    SELECT * FROM {table_name}
                    WHERE updated_at > %s
                    ORDER BY updated_at
                    LIMIT %s
                """
                cursor.execute(query, (last_sync_time, self.batch_size))
            else:
                query = f"""
                    SELECT * FROM {table_name}
                    ORDER BY created_at
                    LIMIT %s
                """
                cursor.execute(query, (self.batch_size,))
            
            records = cursor.fetchall()
            return [dict(record) for record in records]
        
        except Exception as e:
            logger.error(f"Error fetching records from {table_name}: {e}")
            return []
        finally:
            cursor.close()
    
    def sync_transactions(self):
        """Sync transactions table"""
        table_name = 'transactions'
        logger.info(f"📊 Syncing {table_name}...")
        
        last_sync = self.last_sync_times.get(table_name)
        records = self.fetch_new_records(table_name, last_sync)
        
        if not records:
            logger.info(f"  No new records in {table_name}")
            return
        
        # Transform records for ClickHouse
        transformed_records = []
        for record in records:
            transformed = {
                'transaction_id': record['transaction_id'],
                'transaction_hash': record['transaction_hash'],
                'user_id': record['user_id'] or 0,
                'from_wallet_id': record['from_wallet_id'] or 0,
                'to_wallet_id': record['to_wallet_id'] or 0,
                'to_address': record['to_address'] or '',
                'amount': float(record['amount']),
                'currency': record['currency'],
                'usd_amount': float(record['usd_amount']) if record['usd_amount'] else 0.0,
                'fee': float(record['fee']),
                'transaction_type': record['transaction_type'],
                'status': record['status'],
                'network': record['network'] or '',
                'confirmations': record['confirmations'] or 0,
                'block_number': record['block_number'],
                'risk_score': float(record['risk_score']),
                'is_flagged': 1 if record['is_flagged'] else 0,
                'flag_reason': record['flag_reason'] or '',
                'ip_address': str(record['ip_address']) if record['ip_address'] else '0.0.0.0',
                'device_id': record['device_id'] or '',
                'country_code': record['country_code'] or 'XX',
                'created_at': record['created_at'],
                'completed_at': record['completed_at'],
                'updated_at': record['updated_at']
            }
            transformed_records.append(transformed)
        
        # Insert into ClickHouse
        try:
            self.ch_client.insert(
                f'{self.ch_database}.{table_name}',
                transformed_records,
                column_names=list(transformed_records[0].keys())
            )
            logger.info(f"  ✅ Inserted {len(transformed_records)} records into {table_name}")
            
            # Update last sync time
            self.last_sync_times[table_name] = max(r['updated_at'] for r in records)
        
        except Exception as e:
            import traceback
            logger.error(f"  ❌ Failed to insert into {table_name}: {str(e)}")
            logger.error(f"  Full error: {traceback.format_exc()}")
    
    def sync_users(self):
        """Sync users table"""
        table_name = 'users'
        logger.info(f"👥 Syncing {table_name}...")
        
        last_sync = self.last_sync_times.get(table_name)
        records = self.fetch_new_records(table_name, last_sync)
        
        if not records:
            logger.info(f"  No new records in {table_name}")
            return
        
        transformed_records = []
        for record in records:
            transformed = {
                'user_id': record['user_id'],
                'username': record['username'],
                'email': record['email'],
                'full_name': record['full_name'] or '',
                'country_code': record['country_code'] or 'XX',
                'kyc_level': record['kyc_level'],
                'is_verified': 1 if record['is_verified'] else 0,
                'risk_score': float(record['risk_score']),
                'registration_date': record['registration_date'],
                'last_login': record['last_login'],
                'created_at': record['created_at'],
                'updated_at': record['updated_at']
            }
            transformed_records.append(transformed)
        
        try:
            self.ch_client.insert(
                f'{self.ch_database}.{table_name}',
                transformed_records,
                column_names=list(transformed_records[0].keys())
            )
            logger.info(f"  ✅ Inserted {len(transformed_records)} records into {table_name}")
            self.last_sync_times[table_name] = max(r['updated_at'] for r in records)
        
        except Exception as e:
            logger.error(f"  ❌ Failed to insert into {table_name}: {e}")
    
    def sync_wallets(self):
        """Sync wallets table"""
        table_name = 'wallets'
        logger.info(f"💼 Syncing {table_name}...")
        
        last_sync = self.last_sync_times.get(table_name)
        records = self.fetch_new_records(table_name, last_sync)
        
        if not records:
            logger.info(f"  No new records in {table_name}")
            return
        
        transformed_records = []
        for record in records:
            transformed = {
                'wallet_id': record['wallet_id'],
                'user_id': record['user_id'],
                'wallet_address': record['wallet_address'],
                'wallet_type': record['wallet_type'],
                'currency': record['currency'],
                'balance': float(record['balance']),
                'is_active': 1 if record['is_active'] else 0,
                'created_at': record['created_at'],
                'updated_at': record['updated_at']
            }
            transformed_records.append(transformed)
        
        try:
            self.ch_client.insert(
                f'{self.ch_database}.{table_name}',
                transformed_records,
                column_names=list(transformed_records[0].keys())
            )
            logger.info(f"  ✅ Inserted {len(transformed_records)} records into {table_name}")
            self.last_sync_times[table_name] = max(r['updated_at'] for r in records)
        
        except Exception as e:
            logger.error(f"  ❌ Failed to insert into {table_name}: {e}")
    
    def sync_merchants(self):
        """Sync merchants table"""
        table_name = 'merchants'
        logger.info(f"🏪 Syncing {table_name}...")
        
        cursor = self.pg_conn.cursor(cursor_factory=RealDictCursor)
        cursor.execute(f"SELECT * FROM {table_name}")
        records = cursor.fetchall()
        cursor.close()
        
        if not records:
            return
        
        transformed_records = []
        for record in records:
            transformed = {
                'merchant_id': record['merchant_id'],
                'merchant_name': record['merchant_name'],
                'merchant_category': record['merchant_category'] or '',
                'country_code': record['country_code'] or 'XX',
                'risk_level': record['risk_level'],
                'is_active': 1 if record['is_active'] else 0,
                'created_at': record['created_at']
            }
            transformed_records.append(transformed)
        
        try:
            self.ch_client.insert(
                f'{self.ch_database}.{table_name}',
                transformed_records,
                column_names=list(transformed_records[0].keys())
            )
            logger.info(f"  ✅ Inserted {len(transformed_records)} records into {table_name}")
        
        except Exception as e:
            logger.error(f"  ❌ Failed to insert into {table_name}: {e}")
    
    def sync_alerts(self):
        """Sync alerts table"""
        table_name = 'alerts'
        logger.info(f"🚨 Syncing {table_name}...")
        
        last_sync = self.last_sync_times.get(table_name)
        records = self.fetch_new_records(table_name, last_sync)
        
        if not records:
            logger.info(f"  No new records in {table_name}")
            return
        
        transformed_records = []
        for record in records:
            transformed = {
                'alert_id': record['alert_id'],
                'transaction_id': record['transaction_id'],
                'user_id': record['user_id'],
                'alert_type': record['alert_type'],
                'severity': record['severity'],
                'description': record['description'] or '',
                'status': record['status'],
                'assigned_to': record['assigned_to'],
                'created_at': record['created_at'],
                'resolved_at': record['resolved_at']
            }
            transformed_records.append(transformed)
        
        try:
            self.ch_client.insert(
                f'{self.ch_database}.{table_name}',
                transformed_records,
                column_names=list(transformed_records[0].keys())
            )
            logger.info(f"  ✅ Inserted {len(transformed_records)} records into {table_name}")
            self.last_sync_times[table_name] = max(r['created_at'] for r in records)
        
        except Exception as e:
            logger.error(f"  ❌ Failed to insert into {table_name}: {e}")
    
    def run_sync_cycle(self):
        """Run one complete sync cycle"""
        logger.info("=" * 60)
        logger.info(f"🔄 Starting sync cycle at {datetime.now()}")
        logger.info("=" * 60)
        
        try:
            # Sync all tables
            self.sync_users()
            self.sync_wallets()
            self.sync_merchants()
            self.sync_transactions()
            self.sync_alerts()
            
            logger.info("✅ Sync cycle completed successfully")
        
        except Exception as e:
            logger.error(f"❌ Sync cycle failed: {e}")
    
    def start(self):
        """Start continuous sync process"""
        logger.info("🚀 Starting PostgreSQL to ClickHouse sync service...")
        
        # Initial connections
        self.connect_postgres()
        self.connect_clickhouse()
        
        logger.info(f"⏰ Sync interval: {self.sync_interval} seconds")
        logger.info(f"📦 Batch size: {self.batch_size}")
        
        # Continuous sync loop
        while True:
            try:
                self.run_sync_cycle()
                time.sleep(self.sync_interval)
            
            except KeyboardInterrupt:
                logger.info("🛑 Sync service stopped by user")
                break
            
            except Exception as e:
                logger.error(f"❌ Unexpected error: {e}")
                time.sleep(self.sync_interval)
        
        # Cleanup
        if self.pg_conn:
            self.pg_conn.close()
        if self.ch_client:
            self.ch_client.close()


if __name__ == "__main__":
    sync_service = PostgresClickHouseSync()
    sync_service.start()