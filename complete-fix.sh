#!/bin/bash
# complete-fix.sh - Complete Fix for ClickHouse Issues

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}🔧 Complete ClickHouse Fix Script${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Step 1: Stop and clean everything
echo -e "${YELLOW}📦 Step 1: Cleaning up...${NC}"
docker-compose -f docker-compose-clickhouse.yml down -v 2>/dev/null || true
docker volume prune -f
echo -e "${GREEN}✅ Cleanup done${NC}"
echo ""

# Step 2: Remove problematic config files temporarily
echo -e "${YELLOW}🗑️  Step 2: Backing up configs...${NC}"
if [ -f "clickhouse/config.xml" ]; then
    mv clickhouse/config.xml clickhouse/config.xml.backup
    echo "   Backed up config.xml"
fi
if [ -f "clickhouse/users.xml" ]; then
    mv clickhouse/users.xml clickhouse/users.xml.backup
    echo "   Backed up users.xml"
fi
echo -e "${GREEN}✅ Configs backed up${NC}"
echo ""

# Step 3: Start PostgreSQL first
echo -e "${YELLOW}🐘 Step 3: Starting PostgreSQL...${NC}"
docker-compose -f docker-compose-clickhouse.yml up -d postgres-source

echo "   Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if docker-compose -f docker-compose-clickhouse.yml exec -T postgres-source pg_isready -U exchange_admin > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL is ready!${NC}"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

# Step 4: Start ClickHouse
echo -e "${YELLOW}🗄️  Step 4: Starting ClickHouse (without custom configs)...${NC}"
docker-compose -f docker-compose-clickhouse.yml up -d clickhouse

echo "   Waiting for ClickHouse to be ready (this may take 40 seconds)..."
sleep 10

for i in {1..20}; do
    if docker-compose -f docker-compose-clickhouse.yml exec -T clickhouse clickhouse-client --query "SELECT 1" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ ClickHouse is ready!${NC}"
        break
    fi
    echo -n "."
    sleep 3
done
echo ""

# Step 5: Check status
echo -e "${YELLOW}📊 Step 5: Checking status...${NC}"
docker-compose -f docker-compose-clickhouse.yml ps
echo ""

# Step 6: Test connections
echo -e "${YELLOW}🧪 Step 6: Testing connections...${NC}"

echo "Testing PostgreSQL:"
if docker-compose -f docker-compose-clickhouse.yml exec -T postgres-source psql -U exchange_admin -d crypto_exchange -c "SELECT 'PostgreSQL OK!' as status;" 2>/dev/null; then
    echo -e "${GREEN}✅ PostgreSQL connection successful${NC}"
else
    echo -e "${RED}❌ PostgreSQL connection failed${NC}"
fi
echo ""

echo "Testing ClickHouse:"
if docker-compose -f docker-compose-clickhouse.yml exec -T clickhouse clickhouse-client --query "SELECT 'ClickHouse OK!' as status;" 2>/dev/null; then
    echo -e "${GREEN}✅ ClickHouse connection successful${NC}"
else
    echo -e "${RED}❌ ClickHouse connection failed${NC}"
    echo "Showing last 20 lines of ClickHouse logs:"
    docker logs crypto_clickhouse --tail 20
fi
echo ""

# Step 7: Show access info
echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}🎉 Fix Process Complete!${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""
echo -e "${YELLOW}Access Information:${NC}"
echo "  PostgreSQL:     localhost:5434"
echo "  ClickHouse HTTP: localhost:8123"
echo "  ClickHouse Native: localhost:9000"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Check status:  make -f Makefile.clickhouse status"
echo "  2. View logs:     make -f Makefile.clickhouse logs"
echo "  3. Test:          make -f Makefile.clickhouse test"
echo ""
echo -e "${BLUE}================================================================${NC}"