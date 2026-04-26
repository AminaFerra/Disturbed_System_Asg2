#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Testing Distributed System API"
echo "========================================="

# Generate token
echo -e "\n${YELLOW}1. Generating JWT Token...${NC}"
TOKEN=$(python3 generate_token.py | grep "Bearer" | awk '{print $2}')
echo "Token: $TOKEN"

# Test 1: Without token (should fail)
echo -e "\n${YELLOW}2. Testing without token (should fail)...${NC}"
curl -k -s https://localhost/task 2>&1 | head -20

# Test 2: With valid token
echo -e "\n${YELLOW}3. Testing with valid token...${NC}"
curl -k -s -H "Authorization: Bearer $TOKEN" https://localhost/task | python3 -m json.tool 2>/dev/null || echo "Request failed"

# Test 3: Load balancing test (10 requests)
echo -e "\n${YELLOW}4. Testing load balancing (10 requests)...${NC}"
for i in {1..10}; do
    echo -n "Request $i: "
    curl -k -s -H "Authorization: Bearer $TOKEN" https://localhost/task 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('handled_by', 'unknown'))" 2>/dev/null || echo "failed"
done

# Test 4: Rate limiting test (20 rapid requests)
echo -e "\n${YELLOW}5. Testing rate limiting (20 rapid requests)...${NC}"
for i in {1..20}; do
    curl -k -s -H "Authorization: Bearer $TOKEN" https://localhost/task > /dev/null 2>&1 &
done
wait
echo "Check nginx logs for rate limiting messages"

# Test 5: Invalid token
echo -e "\n${YELLOW}6. Testing with invalid token...${NC}"
curl -k -s -H "Authorization: Bearer invalid.token.here" https://localhost/task | python3 -m json.tool 2>/dev/null || echo "Request failed"

echo -e "\n${GREEN}Testing complete!${NC}"
