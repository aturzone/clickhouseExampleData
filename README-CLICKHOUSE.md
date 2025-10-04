# ClickHouse Analytics Setup for Crypto Exchange

## 📋 معرفی

این بخش یک سیستم کامل تحلیل داده برای صرافی ارزهای دیجیتال راه‌اندازی می‌کنه که شامل:

1. **PostgreSQL** - دیتابیس اصلی (OLTP) که تراکنش‌ها رو ذخیره می‌کنه
2. **ClickHouse** - دیتابیس تحلیلی (OLAP) با سرعت بالا برای query های پیچیده
3. **Sync Service** - سرویس خودکار برای انتقال داده از PostgreSQL به ClickHouse
4. **ClickHouse UI** - رابط گرافیکی برای مشاهده و کوئری زدن داده‌ها

---

## 🏗️ معماری سیستم

```
┌─────────────────────────────────────────────────────────┐
│                  PostgreSQL (Source)                     │
│              Transactional Database (OLTP)               │
│  - Users, Wallets, Transactions, Merchants, Alerts      │
│  - Real-time data insertion                             │
│  - Normalized schema for data integrity                 │
└────────────────────┬────────────────────────────────────┘
                     │
                     │ Sync Service (Every 60s)
                     │ - Fetches new/updated records
                     │ - Transforms data
                     │ - Batch inserts
                     ↓
┌─────────────────────────────────────────────────────────┐
│                  ClickHouse (Analytics)                  │
│             Analytics Database (OLAP)                    │
│  - Columnar storage for fast queries                    │
│  - Materialized views for pre-aggregations             │
│  - Optimized for large-scale analytics                 │
│  - Sub-second query performance                        │
└─────────────────────────────────────────────────────────┘
```

---

## 🚀 نصب و راه‌اندازی

### پیش‌نیازها

- Docker & Docker Compose
- حداقل 8GB RAM
- حداقل 20GB فضای دیسک

### راه‌اندازی سریع

```bash
# 1. دادن مجوز اجرا به اسکریپت
chmod +x setup-clickhouse.sh

# 2. اجرای اسکریپت راه‌اندازی
./setup-clickhouse.sh

# 3. چک کردن وضعیت سرویس‌ها
docker-compose -f docker-compose-clickhouse.yml ps
```

### راه‌اندازی دستی

```bash
# ساخت دایرکتوری‌های لازم
mkdir -p sql clickhouse sync-service/logs

# بالا آوردن سرویس‌ها
docker-compose -f docker-compose-clickhouse.yml up -d

# مشاهده لاگ‌ها
docker-compose -f docker-compose-clickhouse.yml logs -f
```

---

## 📊 ساختار داده

### PostgreSQL Tables (Source)

#### 1. **users** - کاربران
- `user_id`, `username`, `email`, `country_code`
- `kyc_level`, `is_verified`, `risk_score`

#### 2. **wallets** - کیف پول‌ها
- `wallet_id`, `user_id`, `wallet_address`
- `currency`, `balance`, `wallet_type`

#### 3. **transactions** - تراکنش‌ها (جدول اصلی)
- اطلاعات مالی: `amount`, `currency`, `usd_amount`, `fee`
- اطلاعات شبکه: `network`, `confirmations`, `block_number`
- امنیت: `risk_score`, `is_flagged`, `flag_reason`
- متادیتا: `ip_address`, `device_id`, `country_code`

#### 4. **merchants** - فروشندگان
- `merchant_id`, `merchant_name`, `merchant_category`
- `risk_level`, `country_code`

#### 5. **alerts** - هشدارها
- `alert_id`, `transaction_id`, `user_id`
- `alert_type`, `severity`, `status`

### ClickHouse Tables (Analytics)

همه جداول PostgreSQL به ClickHouse منتقل می‌شن، به علاوه:

#### Materialized Views (پیش-محاسبه‌شده)

1. **user_transaction_stats** - آمار روزانه کاربران
   - تعداد تراکنش‌ها به تفکیک نوع
   - مجموع، میانگین، بیشترین و کمترین مبلغ
   - آمار ریسک و تراکنش‌های flag شده

2. **hourly_metrics** - آمار ساعتی
   - حجم کل تراکنش‌ها
   - تفکیک به نوع تراکنش
   - آمار ریسک
   - وضعیت تراکنش‌ها

---

## 🔍 نمونه Query های کاربردی

### 1. تعداد کل تراکنش‌ها

```sql
SELECT COUNT(*) as total_transactions
FROM crypto_analytics.transactions;
```

### 2. تراکنش‌های پرریسک (Risk Score > 70)

```sql
SELECT 
    transaction_id,
    user_id,
    amount,
    currency,
    risk_score,
    flag_reason,
    created_at
FROM crypto_analytics.transactions
WHERE risk_score > 70
ORDER BY risk_score DESC
LIMIT 100;
```

### 3. آمار روزانه یک کاربر خاص

```sql
SELECT 
    date,
    total_transactions,
    total_amount_usd,
    avg_amount_usd,
    flagged_count,
    avg_risk_score
FROM crypto_analytics.user_transaction_stats
WHERE user_id = 1
ORDER BY date DESC
LIMIT 30;
```

### 4. حجم معاملات ساعتی امروز

```sql
SELECT 
    hour,
    total_transactions,
    total_volume_usd,
    flagged_transactions,
    avg_risk_score
FROM crypto_analytics.hourly_metrics
WHERE toDate(hour) = today()
ORDER BY hour DESC;
```

### 5. کاربران با بیشترین تراکنش در 24 ساعت گذشته

```sql
SELECT 
    user_id,
    COUNT(*) as transaction_count,
    SUM(usd_amount) as total_volume,
    AVG(risk_score) as avg_risk
FROM crypto_analytics.transactions
WHERE created_at >= now() - INTERVAL 1 DAY
GROUP BY user_id
ORDER BY transaction_count DESC
LIMIT 20;
```

### 6. تراکنش‌های مشکوک (Anomaly Patterns)

```sql
-- تراکنش‌های بزرگ (> $10,000)
SELECT *
FROM crypto_analytics.transactions
WHERE usd_amount > 10000
  AND created_at >= now() - INTERVAL 7 DAY
ORDER BY usd_amount DESC;

-- تراکنش‌های سریع متوالی
SELECT 
    user_id,
    COUNT(*) as rapid_tx_count,
    SUM(usd_amount) as total_amount,
    min(created_at) as first_tx,
    max(created_at) as last_tx
FROM crypto_analytics.transactions
WHERE created_at >= now() - INTERVAL 1 HOUR
GROUP BY user_id
HAVING rapid_tx_count >= 5
ORDER BY rapid_tx_count DESC;
```

### 7. آمار بر اساس کشور

```sql
SELECT 
    country_code,
    COUNT(*) as transaction_count,
    SUM(usd_amount) as total_volume,
    AVG(risk_score) as avg_risk,
    SUM(is_flagged) as flagged_count
FROM crypto_analytics.transactions
WHERE created_at >= now() - INTERVAL 30 DAY
GROUP BY country_code
ORDER BY total_volume DESC;
```

---

## 🎨 استفاده از ClickHouse UI (Tabix)

1. باز کردن مرورگر: `http://localhost:8124`
2. اتصال به ClickHouse:
   - Host: `clickhouse`
   - Port: `8123`
   - User: `analytics_user`
   - Password: `ClickHouse2024!`
   - Database: `crypto_analytics`

---

## 🔧 تنظیمات Sync Service

سرویس همگام‌سازی به صورت خودکار هر 60 ثانیه داده‌ها رو از PostgreSQL به ClickHouse منتقل می‌کنه.

### تغییر فاصله زمانی Sync

در فایل `docker-compose-clickhouse.yml`:

```yaml
pg-to-clickhouse-sync:
  environment:
    SYNC_INTERVAL: 30  # تغییر به 30 ثانیه
    BATCH_SIZE: 2000   # افزایش اندازه batch
```

### مشاهده لاگ‌های Sync

```bash
docker-compose -f docker-compose-clickhouse.yml logs -f pg-to-clickhouse-sync
```

---

## 📈 بهینه‌سازی Performance

### 1. افزایش منابع ClickHouse

در `docker-compose-clickhouse.yml`:

```yaml
clickhouse:
  deploy:
    resources:
      limits:
        cpus: '8.0'
        memory: 16G
```

### 2. تنظیم Memory Settings

در `clickhouse/config.xml`:

```xml
<max_memory_usage>20000000000</max_memory_usage>
```

### 3. ایجاد Index های اضافی

```sql
ALTER TABLE crypto_analytics.transactions 
ADD INDEX idx_user_created (user_id, created_at) TYPE minmax GRANULARITY 4;
```

---

## 🔒 امنیت

### تغییر پسوردها

**قبل از production حتماً پسوردها رو تغییر بدید:**

1. PostgreSQL: در `.env` یا `docker-compose-clickhouse.yml`
2. ClickHouse: در `clickhouse/users.xml`
3. Sync Service: در `docker-compose-clickhouse.yml`

### محدود کردن دسترسی شبکه

```yaml
clickhouse:
  ports:
    # فقط از localhost قابل دسترسی باشه
    - "127.0.0.1:8123:8123"
    - "127.0.0.1:9000:9000"
```

---

## 🧪 تست و Debugging

### 1. تست اتصال PostgreSQL

```bash
docker-compose -f docker-compose-clickhouse.yml exec postgres-source \
  psql -U exchange_admin -d crypto_exchange -c "SELECT COUNT(*) FROM transactions;"
```

### 2. تست اتصال ClickHouse

```bash
docker-compose -f docker-compose-clickhouse.yml exec clickhouse \
  clickhouse-client --query "SELECT COUNT(*) FROM crypto_analytics.transactions;"
```

### 3. چک کردن وضعیت Sync

```bash
# لاگ‌های 100 خط آخر
docker-compose -f docker-compose-clickhouse.yml logs --tail=100 pg-to-clickhouse-sync

# مشاهده live
docker-compose -f docker-compose-clickhouse.yml logs -f pg-to-clickhouse-sync
```

---

## 🛠️ عیب‌یابی مشکلات متداول

### مشکل: ClickHouse start نمیشه

```bash
# چک کردن لاگ‌ها
docker-compose -f docker-compose-clickhouse.yml logs clickhouse

# ریستارت سرویس
docker-compose -f docker-compose-clickhouse.yml restart clickhouse

# چک کردن resource usage
docker stats
```

### مشکل: Sync داده‌ها رو منتقل نمیکنه

```bash
# چک کردن اتصالات
docker-compose -f docker-compose-clickhouse.yml exec pg-to-clickhouse-sync \
  python -c "import psycopg2; print('PG OK')"

# ریستارت sync service
docker-compose -f docker-compose-clickhouse.yml restart pg-to-clickhouse-sync
```

### مشکل: Query ها کند هستن

```sql
-- چک کردن merge ها
SELECT * FROM system.merges;

-- چک کردن query های در حال اجرا
SELECT * FROM system.processes;

-- Optimize کردن جدول
OPTIMIZE TABLE crypto_analytics.transactions FINAL;
```

---

## 📚 منابع بیشتر

- [ClickHouse Official Docs](https://clickhouse.com/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

---

## 🚦 مراحل بعدی

بعد از اینکه این بخش راه افتاد، میتونید:

1. ✅ **Airflow DAG اضافه کنید** - برای دریافت خودکار داده از ClickHouse
2. ✅ **ML Model بسازید** - برای تشخیص Anomaly ها
3. ✅ **Streamlit Dashboard** - برای نمایش نتایج
4. ✅ **Alert System** - برای هشدار تراکنش‌های مشکوک

---

## 📝 License

MIT License - استفاده آزاد برای هر منظوری