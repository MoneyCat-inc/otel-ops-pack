#!/bin/bash
# SigNoz Stack Startup Script
# Ensures proper initialization order and schema migration

set -e

echo "🚀 Starting SigNoz Observability Stack..."

# Start core services
echo "📦 Starting ZooKeeper and ClickHouse..."
docker-compose -f docker-compose-signoz.yml up -d signoz-zookeeper signoz-clickhouse

# Wait for ClickHouse to be ready
echo "⏳ Waiting for ClickHouse to be ready..."
until docker exec signoz-clickhouse clickhouse-client --query "SELECT 1" >/dev/null 2>&1; do
  echo "   ClickHouse not ready yet, waiting..."
  sleep 5
done

echo "✅ ClickHouse is ready!"

# Run schema migration
echo "🔧 Running SigNoz schema migration..."
docker-compose -f docker-compose-signoz.yml run --rm signoz-schema-migrator

echo "✅ Schema migration completed!"

# Start remaining services
echo "📊 Starting SigNoz collector and frontend..."
docker-compose -f docker-compose-signoz.yml up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Verify services
echo "🔍 Verifying services..."
docker-compose -f docker-compose-signoz.yml ps

echo "🎉 SigNoz stack is ready!"
echo "   - SigNoz UI: http://localhost:8080"
echo "   - OTLP gRPC: localhost:4317"
echo "   - OTLP HTTP: localhost:4318"
echo "   - ClickHouse: localhost:8123"


