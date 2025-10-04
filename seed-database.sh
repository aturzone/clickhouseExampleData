#!/bin/bash
# seed-database.sh - Add data to PostgreSQL

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}🌱 Seeding PostgreSQL Database${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Check if PostgreSQL is running
if ! docker-compose -f docker-compose-clickhouse.yml ps postgres-source | grep -q "Up"; then
    echo -e "${YELLOW}Starting PostgreSQL...${NC}"
    docker-compose -f docker-compose-clickhouse.yml up -d postgres-source
    sleep 5
fi

# Seed data
echo -e "${YELLOW}📊 Inserting seed data...${NC}"
docker-compose -f docker-compose-clickhouse.yml exec -T postgres-source \
    psql -U exchange_admin -d crypto_exchange < sql/seed-data.sql

echo ""
echo -e "${YELLOW}📈 Checking data counts...${NC}"
docker-compose -f docker-compose-clickhouse.yml exec -T postgres-source \
    psql -U exchange_admin -d crypto_exchange -c "
    SELECT 'Users' as table_name, COUNT(*) as count FROM users
    UNION ALL
    SELECT 'Wallets', COUNT(*) FROM wallets
    UNION ALL
    SELECT 'Transactions', COUNT(*) FROM transactions
    UNION ALL
    SELECT 'Merchants', COUNT(*) FROM merchants
    UNION ALL
    SELECT 'Alerts', COUNT(*) FROM alerts
    ORDER BY table_name;
"

echo ""
echo -e "${GREEN}✅ Database seeded successfully!${NC}"
echo -e "${BLUE}================================================================${NC}"