#!/bin/bash
# setup-clickhouse.sh
# راه‌اندازی کامل PostgreSQL + ClickHouse + Sync Service

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}🚀 Setting up Crypto Exchange Analytics System${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Create required directories
echo -e "${YELLOW}📁 Creating directories...${NC}"
mkdir -p sql
mkdir -p clickhouse
mkdir -p sync-service
mkdir -p sync-service/logs

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Stop any existing containers
echo -e "${YELLOW}🛑 Stopping existing containers...${NC}"
docker-compose -f docker-compose-clickhouse.yml down -v 2>/dev/null || true

# Start services
echo -e "${YELLOW}🚀 Starting services...${NC}"
docker-compose -f docker-compose-clickhouse.yml up -d postgres-source clickhouse

# Wait for PostgreSQL
echo -e "${YELLOW}⏳ Waiting for PostgreSQL to be ready...${NC}"
sleep 10
until docker-compose -f docker-compose-clickhouse.yml exec -T postgres-source pg_isready -U exchange_admin -d crypto_exchange > /dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e "${GREEN}✅ PostgreSQL is ready!${NC}"

# Wait for ClickHouse
echo -e "${YELLOW}⏳ Waiting for ClickHouse to be ready...${NC}"
sleep 5
until docker-compose -f docker-compose-clickhouse.yml exec -T clickhouse clickhouse-client --query "SELECT 1" > /dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e "${GREEN}✅ ClickHouse is ready!${NC}"

# Start sync service
echo -e "${YELLOW}🔄 Starting sync service...${NC}"
docker-compose -f docker-compose-clickhouse.yml up -d pg-to-clickhouse-sync

# Start ClickHouse UI
echo -e "${YELLOW}🎨 Starting ClickHouse UI...${NC}"
docker-compose -f docker-compose-clickhouse.yml up -d clickhouse-tabix

# Wait a bit for sync to start
sleep 5

echo ""
echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}🎉 Setup completed successfully!${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""
echo -e "${GREEN}📊 Access Points:${NC}"
echo -e "  • PostgreSQL (Source DB):  localhost:5434"
echo -e "  • ClickHouse HTTP:         localhost:8123"
echo -e "  • ClickHouse Native:       localhost:9000"
echo -e "  • ClickHouse UI (Tabix):   http://localhost:8124"
echo ""
echo -e "${GREEN}🔑 Credentials:${NC}"
echo -e "  PostgreSQL:"
echo -e "    - User: exchange_admin"
echo -e "    - Password: Exchange2024Secure!"
echo -e "    - Database: crypto_exchange"
echo ""
echo -e "  ClickHouse:"
echo -e "    - User: analytics_user"
echo -e "    - Password: ClickHouse2024!"
echo -e "    - Database: crypto_analytics"
echo ""
echo -e "${GREEN}📋 Useful Commands:${NC}"
echo -e "  • View logs:         docker-compose -f docker-compose-clickhouse.yml logs -f"
echo -e "  • View sync logs:    docker-compose -f docker-compose-clickhouse.yml logs -f pg-to-clickhouse-sync"
echo -e "  • Stop services:     docker-compose -f docker-compose-clickhouse.yml down"
echo -e "  • Restart sync:      docker-compose -f docker-compose-clickhouse.yml restart pg-to-clickhouse-sync"
echo ""
echo -e "${GREEN}🔍 Quick Test:${NC}"
echo -e "  Check PostgreSQL data:"
echo -e "    docker-compose -f docker-compose-clickhouse.yml exec postgres-source psql -U exchange_admin -d crypto_exchange -c 'SELECT COUNT(*) FROM transactions;'"
echo ""
echo -e "  Check ClickHouse data:"
echo -e "    docker-compose -f docker-compose-clickhouse.yml exec clickhouse clickhouse-client --query 'SELECT COUNT(*) FROM crypto_analytics.transactions;'"
echo ""
echo -e "${BLUE}================================================================${NC}"