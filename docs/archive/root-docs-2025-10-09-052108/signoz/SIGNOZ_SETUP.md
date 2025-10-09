# SigNoz Observability Stack

This directory contains the complete SigNoz observability stack configuration with proper ClickHouse cluster setup and schema migration.

## 🚀 Quick Start

### Windows (PowerShell)
```powershell
.\start-signoz.ps1
```

### Linux/macOS (Bash)
```bash
chmod +x start-signoz.sh
./start-signoz.sh
```

### Manual Setup
```bash
# Start core services
docker-compose -f docker-compose-signoz.yml up -d signoz-zookeeper signoz-clickhouse

# Wait for ClickHouse to be ready
docker exec signoz-clickhouse clickhouse-client --query "SELECT 1"

# Run schema migration
docker-compose -f docker-compose-signoz.yml run --rm signoz-schema-migrator-sync

# Start remaining services
docker-compose -f docker-compose-signoz.yml up -d
```

## 📊 Services

| Service | Port | Description |
|---------|------|-------------|
| SigNoz UI | 8080 | Web interface for observability |
| OTLP gRPC | 14317 | OpenTelemetry gRPC receiver |
| OTLP HTTP | 14318 | OpenTelemetry HTTP receiver |
| ClickHouse | 8123 | ClickHouse HTTP interface |
| ClickHouse | 9000 | ClickHouse native interface |
| ZooKeeper | 2181 | Coordination service |

## 🔧 Configuration Files

- `docker-compose-signoz.yml` - Complete SigNoz stack with proper dependencies
- `clickhouse-cluster-config.xml` - ClickHouse cluster configuration
- `clickhouse-zookeeper-config.xml` - ZooKeeper integration
- `config.yaml` - OpenTelemetry collector configuration

## 🎯 Key Features

- ✅ **Proper Schema Migration**: Uses official `signoz-schema-migrator-sync` for correct table creation
- ✅ **ClickHouse Cluster**: Single-node cluster configuration for distributed tables
- ✅ **ZooKeeper Integration**: Required for ClickHouse distributed operations
- ✅ **Health Checks**: All services include health monitoring
- ✅ **Persistent Volumes**: Data survives container recreation
- ✅ **Windows Compatibility**: Mapped ports for Windows collector integration

## 🔍 Verification

After startup, verify the stack is working:

```bash
# Check services
docker-compose -f docker-compose-signoz.yml ps

# Verify ClickHouse schema
docker exec signoz-clickhouse clickhouse-client --query "SHOW TABLES FROM signoz_logs"

# Test data ingestion
docker exec signoz-clickhouse clickhouse-client --query "SELECT count() FROM signoz_logs.distributed_logs_v2 WHERE JSONExtractString(body, 'dataset') = 'agent_queue'"
```

## 🚨 Troubleshooting

### Schema Migration Issues
If tables are missing, re-run the migration:
```bash
docker-compose -f docker-compose-signoz.yml run --rm signoz-schema-migrator-sync
```

### ClickHouse Connection Issues
Check if ClickHouse is ready:
```bash
docker exec signoz-clickhouse clickhouse-client --query "SELECT 1"
```

### Collector Errors
Check collector logs:
```bash
docker logs signoz-otel-collector --tail 50
```

## 📝 Notes

- The schema migration runs automatically on first startup
- ClickHouse data is persisted in the `clickhouse_data` volume
- All services restart automatically unless stopped
- The stack uses the `otel_default` network for service communication


