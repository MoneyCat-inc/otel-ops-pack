# Agent Queue Configuration Guide

## Environment Variables

The agent queue system supports the following environment variables:

### Queue Driver
- `QUEUE_DRIVER`: Controls the queue storage backend
  - `json` (default): Use JSON file-based queue
  - `sqlite`: Use SQLite database with WAL support

### WAL Mode
- `QUEUE_WAL`: Enable Write-Ahead Logging for SQLite
  - `0` (default): Disable WAL
  - `1`: Enable WAL for better concurrency

### Shadow Mode
- `QUEUE_SHADOW`: Enable shadow writes for testing
  - `1` (default): Write to shadow artifacts only
  - `0`: Write to canonical artifacts

### Queue Limits
- `QUEUE_MAX_JOBS`: Maximum concurrent jobs (default: 2)
- `QUEUE_MAX_FILES`: Maximum files per job (default: 10)
- `QUEUE_MAX_LINES`: Maximum lines per job (default: 200)

## Usage Examples

### Enable SQLite with WAL
```bash
QUEUE_DRIVER=sqlite QUEUE_WAL=1 npm run agent:status
```

### Enable shadow mode for testing
```bash
QUEUE_SHADOW=1 npm run agent:migrate
```

### Check queue status
```bash
npm run agent:status
```

### Run migration from JSON to SQLite
```bash
npm run agent:migrate
```

### Test SQLite functionality
```bash
npm run agent:test-sqlite
```

## Migration Process

1. **PR-A Complete**: SQLite DAL implemented in shadow mode
2. **PR-B Next**: Runner admission control + shadow writes
3. **PR-C Next**: Offline cross-origin isolation
4. **PR-D Final**: Flip to canonical writes

## Database Schema

### Jobs Table
- `id`: Unique job identifier
- `kind`: Job type/category
- `payload_json`: JSON-encoded job data
- `priority`: Job priority (higher = more important)
- `attempts`: Number of execution attempts
- `max_attempts`: Maximum retry attempts
- `not_before`: Earliest execution timestamp
- `created_at`: Job creation timestamp
- `ttl_ms`: Time-to-live in milliseconds
- `status`: Current job status (pending/running/completed/failed/expired)

### Runs Table
- `id`: Unique run identifier
- `job_id`: Reference to jobs table
- `started_at`: Run start timestamp
- `finished_at`: Run completion timestamp
- `exit_code`: Process exit code
- `stdout`: Standard output
- `stderr`: Standard error
- `metrics_json`: JSON-encoded performance metrics



