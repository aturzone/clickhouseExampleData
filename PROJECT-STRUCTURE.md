# 📁 ساختار کامل پروژه ClickHouse Analytics

این سند ساختار کامل پروژه و توضیح هر فایل رو شامل میشه.

---

## 🌳 ساختار فولدر

```
clickhouse-analytics/
│
├── 📄 docker-compose-clickhouse.yml    # تنظیمات اصلی Docker Compose
├── 📄 setup-clickhouse.sh              # اسکریپت راه‌اندازی خودکار
├── 📄 Makefile.clickhouse              # دستورات راحت برای مدیریت
│
├── 📄 README-CLICKHOUSE.md             # مستندات کامل
├── 📄 QUICKSTART.md                    # راهنمای شروع سریع
├── 📄 PROJECT-STRUCTURE.md             # این فایل!
│
├── 📄 .gitignore.clickhouse            # فایل‌های ignore شده
├── 📄 .env.clickhouse.example          # نمونه تنظیمات محیطی
│
├── 📂 sql/                              # فایل‌های SQL
│   ├── init-source-db.sql              # ساخت schema PostgreSQL
│   ├── seed-data.sql                   # داده‌های فرضی اولیه
│   └── init-clickhouse.sql             # ساخت schema ClickHouse
│
├── 📂 clickhouse/                       # تنظیمات ClickHouse
│   ├── config.xml                      # تنظیمات سرور
│   └── users.xml                       # تنظیمات کاربران
│
├── 📂 sync-service/                     # سرویس همگام‌سازی
│   ├── Dockerfile                      # Docker image برای sync
│   ├── requirements.txt                # وابستگی‌های Python
│   ├── sync.py                         # کد اصلی sync
│   └── logs/                           # لاگ‌های sync service
│       └── .gitkeep
│
├── 📂 backups/                          # بکاپ‌های دیتابیس
│   └── .gitkeep
│
└── 📄 اسکریپت‌های Python (root یا tools/)
    ├── clickhouse-queries.py           # نمونه query ها
    └── data-generator.py               # تولید داده فرضی
```

---

## 📄 توضیح فایل‌ها

### 🐳 Docker & Orchestration

#### `docker-compose-clickhouse.yml`
**نقش**: فایل اصلی Docker Compose که تمام سرویس‌ها رو تعریف میکنه

**سرویس‌ها**:
- `postgres-source`: دیتابیس PostgreSQL (منبع اصلی)
- `clickhouse`: دیتابیس ClickHouse (تحلیلی)
- `pg-to-clickhouse-sync`: سرویس همگام‌سازی
- `clickhouse-tabix`: رابط گرافیکی ClickHouse

**پورت‌های باز**:
- `5434`: PostgreSQL
- `8123`: ClickHouse HTTP API
- `9000`: ClickHouse Native Protocol
- `8124`: ClickHouse UI

---

### 🗄️ SQL Files

#### `sql/init-source-db.sql`
**نقش**: ساخت schema اولیه PostgreSQL

**جداول**:
- `users` - کاربران صرافی
- `wallets` - کیف پول‌ها
- `transactions` - تراکنش‌ها (جدول اصلی)
- `merchants` - فروشندگان
- `merchant_transactions` - تراکنش‌های merchant
- `alerts` - هشدارها
- `audit_log` - لاگ حسابرسی

**ویژگی‌ها**:
- Index های بهینه شده
- Trigger برای `updated_at`
- Foreign key constraints

#### `sql/seed-data.sql`
**نقش**: تولید داده‌های فرضی برای تست

**داده‌ها**:
- 100 کاربر
- 20 merchant
- 200-400 wallet
- 5000+ تراکنش عادی
- 500 تراکنش مشکوک با انواع anomaly

**انواع Anomaly**:
- Large amounts (مبالغ بزرگ)
- Rapid succession (سرعت بالا)
- High-risk countries (کشورهای پرریسک)

#### `sql/init-clickhouse.sql`
**نقش**: ساخت schema تحلیلی ClickHouse

**جداول اصلی**:
- `transactions` - نسخه بهینه شده برای تحلیل
- `users`, `wallets`, `merchants` - جداول dimensional
- `alerts` - هشدارهای تحلیل شده

**Materialized Views**:
- `user_transaction_stats` - آمار روزانه کاربران
- `hourly_metrics` - آمار ساعتی کل سیستم

**بهینه‌سازی‌ها**:
- `MergeTree` engine
- Partitioning به ماه
- `LowCardinality` برای ستون‌های تکراری
- Compression با ZSTD
- TTL برای حذف خودکار داده‌های قدیمی

---

### ⚙️ ClickHouse Configuration

#### `clickhouse/config.xml`
**تنظیمات**:
- Network: listen روی همه interface ها
- Memory: حداکثر 10GB
- Logging: سطح information
- Compression: ZSTD سطح 3
- Connections: حداکثر 4096

#### `clickhouse/users.xml`
**کاربران**:
- `analytics_user`: دسترسی به `crypto_analytics` database
- `default`: دسترسی محدود local

---

### 🔄 Sync Service

#### `sync-service/sync.py`
**نقش**: همگام‌سازی خودکار PostgreSQL → ClickHouse

**قابلیت‌ها**:
- Incremental sync بر اساس `updated_at`
- Batch processing برای کارایی بهتر
- Transform داده برای سازگاری با ClickHouse
- Error handling و retry
- Logging کامل

**جداول sync شده**:
- users
- wallets
- merchants
- transactions
- alerts

**فاصله پیش‌فرض**: هر 60 ثانیه

#### `sync-service/Dockerfile`
**Base Image**: `python:3.11-slim`

**Dependencies**:
- psycopg2-binary (PostgreSQL)
- clickhouse-connect (ClickHouse)
- python-dateutil

---

### 🛠️ Scripts & Tools

#### `setup-clickhouse.sh`
**نقش**: راه‌اندازی خودکار تمام سیستم

**مراحل**:
1. ساخت دایرکتوری‌ها
2. Stop کردن container های قدیمی
3. Start کردن PostgreSQL
4. Start کردن ClickHouse
5. Start کردن Sync Service
6. نمایش اطلاعات دسترسی

#### `Makefile.clickhouse`
**دستورات اصلی**:
- `setup`: راه‌اندازی اولیه
- `start/stop/restart`: مدیریت سرویس‌ها
- `logs`: نمایش لاگ‌ها
- `test`: تست سلامت سیستم
- `stats`: نمایش آمار
- `clean`: پاکسازی

#### `clickhouse-queries.py`
**نقش**: نمونه query های آماده برای anomaly detection

**توابع**:
- `get_high_risk_transactions()`: تراکنش‌های پرریسک
- `detect_velocity_anomalies()`: ناهنجاری‌های سرعتی
- `detect_large_amount_anomalies()`: مبالغ غیرعادی
- `detect_geographic_anomalies()`: ناهنجاری‌های جغرافیایی
- `detect_round_amount_anomalies()`: مبالغ round
- `get_user_behavior_baseline()`: baseline رفتاری
- `export_anomalies_report()`: گزارش کامل

#### `data-generator.py`
**نقش**: تولید مداوم داده‌های فرضی

**Modes**:
- `continuous`: تولید مداوم با فاصله مشخص
- `burst`: تولید سریع برای یک کاربر (velocity anomaly)

**پارامترها**:
- `--interval`: فاصله بین batch ها
- `--batch-size`: تعداد تراکنش در هر batch
- `--anomaly-rate`: نسبت anomaly ها

---

### 📚 Documentation

#### `README-CLICKHOUSE.md`
**محتوا**:
- معرفی کامل سیستم
- معماری
- دستورالعمل نصب
- نمونه query ها
- بهینه‌سازی
- امنیت
- Troubleshooting

#### `QUICKSTART.md`
**محتوا**:
- راهنمای سریع 10 دقیقه‌ای
- Step-by-step setup
- اولین query ها
- عیب‌یابی سریع
- Checklist موفقیت

#### `PROJECT-STRUCTURE.md` (این فایل)
**محتوا**:
- ساختار کامل پروژه
- توضیح هر فایل
- Data flow
- Port mapping

---

## 🔄 جریان داده (Data Flow)

```
1. PostgreSQL (Source - OLTP)
   └─> تراکنش‌های real-time
       │
       ↓
2. Sync Service (Every 60s)
   └─> خواندن رکوردهای جدید/تغییر یافته
   └─> Transform داده
   └─> Batch insert
       │
       ↓
3. ClickHouse (Analytics - OLAP)
   └─> ذخیره در جداول columnar
   └─> محاسبه Materialized Views
   └─> آماده برای query
       │
       ↓
4. Query Layer
   ├─> ClickHouse UI (Tabix)
   ├─> Python Scripts
   └─> Airflow DAGs (آینده)
```

---

## 🔌 Port Mapping

| سرویس | Internal | External | توضیح |
|-------|----------|----------|-------|
| PostgreSQL | 5432 | 5434 | دیتابیس منبع |
| ClickHouse HTTP | 8123 | 8123 | API برای query |
| ClickHouse Native | 9000 | 9000 | Protocol بومی |
| ClickHouse UI | 80 | 8124 | رابط گرافیکی |

---

## 🔐 Credentials (پیش‌فرض)

### PostgreSQL
- **Host**: localhost:5434
- **User**: exchange_admin
- **Password**: Exchange2024Secure!
- **Database**: crypto_exchange

### ClickHouse
- **HTTP**: localhost:8123
- **Native**: localhost:9000
- **User**: analytics_user
- **Password**: ClickHouse2024!
- **Database**: crypto_analytics

⚠️ **مهم**: قبل از production حتماً پسوردها رو تغییر بدید!

---

## 📊 حجم داده (تقریبی)

### PostgreSQL (بعد از seed)
- Users: 100 رکورد
- Wallets: ~300 رکورد
- Transactions: ~5,500 رکورد
- Merchants: 20 رکورد
- Alerts: ~500 رکورد

### ClickHouse (بعد از اولین sync)
- همه جداول sync میشن
- + Materialized views محاسبه میشن
- فضای دیسک: ~50-100 MB (با compression)

### با Data Generator مداوم
- تولید: 10 تراکنش / 5 ثانیه
- روزانه: ~17,000 تراکنش
- ماهانه: ~500,000 تراکنش

---

## 🎯 Use Cases

این سیستم برای موارد زیر مناسبه:

1. ✅ **آموزش**: یادگیری ClickHouse و CDC
2. ✅ **Development**: توسعه ML models برای anomaly detection
3. ✅ **Testing**: تست pipeline های داده
4. ✅ **Prototyping**: پروتوتایپ سیستم تحلیل real-time
5. ✅ **Demo**: نمایش قابلیت‌های ClickHouse

❌ **NOT for**:
- Production بدون تغییرات امنیتی
- داده‌های واقعی بدون anonymization
- Scale بالای enterprise بدون tuning

---

## 🚀 مراحل بعدی

بعد از راه‌اندازی موفق:

1. ✅ اضافه کردن Airflow DAG برای خواندن از ClickHouse
2. ✅ پیاده‌سازی ML model (Isolation Forest, Clustering)
3. ✅ ساخت Streamlit Dashboard برای visualization
4. ✅ پیاده‌سازی Real-time Alert System
5. ✅ اضافه کردن Grafana برای monitoring

---

## 📝 توضیحات تکمیلی

برای اطلاعات بیشتر:
- راهنمای کامل: `README-CLICKHOUSE.md`
- شروع سریع: `QUICKSTART.md`
- نمونه کدها: `clickhouse-queries.py`
- تولید داده: `data-generator.py`

---

**آخرین بروزرسانی**: 2025-01-04
**نسخه**: 1.0.0