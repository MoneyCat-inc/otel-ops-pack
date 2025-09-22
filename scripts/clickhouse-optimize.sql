-- ClickHouse optimization script for SigNoz performance
-- Add TTLs to hot tables to keep merges fast

-- Logs table TTL (7 days) - timestamp is UInt64, need to convert
ALTER TABLE signoz_logs.logs_v2 MODIFY TTL toDate(toDateTime(timestamp/1000000000)) + INTERVAL 7 DAY;

-- Traces table TTL (30 days for traces, longer retention) - convert DateTime64 to Date
ALTER TABLE signoz_traces.signoz_index_v2 MODIFY TTL toDate(timestamp) + INTERVAL 30 DAY;

-- Show current TTL settings
SELECT 
    database,
    table,
    ttl_info
FROM system.tables 
WHERE database IN ('signoz_logs', 'signoz_traces', 'signoz_metrics')
  AND name LIKE '%v2';
