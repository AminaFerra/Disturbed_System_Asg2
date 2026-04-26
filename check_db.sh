#!/bin/bash

echo "========================================="
echo "Database Status Check"
echo "========================================="

# Check if PostgreSQL is running
echo -e "\n1. Checking PostgreSQL status..."
docker exec postgres_db pg_isready -U postgres

# Show audit logs
echo -e "\n2. Latest Audit Logs:"
docker exec postgres_db psql -U postgres -d audit_logs -c "SELECT request_id, service_name, state, status, timestamp FROM audit_logs ORDER BY timestamp DESC LIMIT 10;" 2>/dev/null || echo "No data yet"

# Show request states
echo -e "\n3. Request States Summary:"
docker exec postgres_db psql -U postgres -d audit_logs -c "SELECT status, COUNT(*) as count FROM requests GROUP BY status ORDER BY count DESC;" 2>/dev/null || echo "No data yet"

# Show full request flow
echo -e "\n4. Complete Request Flow:"
docker exec postgres_db psql -U postgres -d audit_logs -c "SELECT * FROM request_flow_view LIMIT 5;" 2>/dev/null || echo "No data yet"

echo -e "\n5. Check RabbitMQ Status:"
curl -s -u guest:guest http://localhost:15672/api/queues 2>/dev/null | python3 -c "import sys,json; data=json.load(sys.stdin); [print(f\"Queue: {q['name']}, Messages: {q['messages']}\") for q in data if q['name']=='tasks']" 2>/dev/null || echo "RabbitMQ not accessible"

echo -e "\nDone!"
