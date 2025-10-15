# Security & Notifications Archiver Cheatsheet

**Authority**: BossCat OEM | Security Conveyor System  
**Purpose**: Local-first archival of GitHub Code Scanning alerts, analyses, and notifications

---

## Quick Start

### Security Alerts Archive

```bash
# Dry run first (recommended)
pnpm sec:archive:dry

# Archive alerts only (default: 200 per run)
pnpm sec:archive:alerts

# Archive analyses only (SARIF files)
pnpm sec:archive:analyses

# Archive both alerts + analyses (default)
pnpm sec:archive

# Full archive (500 per run)
pnpm sec:archive:full
```

### Notifications Archive

```bash
# Dry run
pnpm notify:archive:dry

# Archive notifications (JSON + Markdown)
pnpm notify:archive

# Archive + mark as read (requires PAT classic with notifications scope)
pnpm notify:archive:mark
```

### Index Maintenance

```bash
# Rebuild indexes from local artifacts (no API calls)
pnpm sec:index
```

---

## PowerShell Direct Usage

### Security Archiver

**Basic Usage:**
```powershell
# Minimal - alerts only
pwsh BRAV/SCPT/sec-archiver/run-security.ps1 `
  -Owner MoneyCat-inc `
  -Repo otel-ops-pack `
  -Mode alerts `
  -ChunkSize 200

# Full - alerts + analyses
pwsh BRAV/SCPT/sec-archiver/run-security.ps1 `
  -Owner MoneyCat-inc `
  -Repo otel-ops-pack `
  -Mode alerts+analyses `
  -ChunkSize 200

# Dry run (no writes)
pwsh BRAV/SCPT/sec-archiver/run-security.ps1 `
  -Owner MoneyCat-inc `
  -Repo otel-ops-pack `
  -Mode alerts+analyses `
  -ChunkSize 50 `
  -DryRun
```

**Advanced Options:**
```powershell
# Custom chunk range
pwsh BRAV/SCPT/sec-archiver/run-security.ps1 `
  -Owner MoneyCat-inc `
  -Repo otel-ops-pack `
  -Mode alerts `
  -ChunkOffset 100 `
  -ChunkSize 200

# Include dismissed and fixed alerts
pwsh BRAV/SCPT/sec-archiver/run-security.ps1 `
  -Owner MoneyCat-inc `
  -Repo otel-ops-pack `
  -Mode alerts `
  -IncludeDismissed `
  -IncludeFixed

# Rate limiting (QPS)
pwsh BRAV/SCPT/sec-archiver/run-security.ps1 `
  -Owner MoneyCat-inc `
  -Repo otel-ops-pack `
  -Mode analyses `
  -GetQps 2.0 `
  -MutateQps 1.0
```

**Delete Old Analyses:**
```powershell
# Delete analyses older than 180 days (requires archived SARIF)
pwsh BRAV/SCPT/sec-archiver/run-security.ps1 `
  -Owner MoneyCat-inc `
  -Repo otel-ops-pack `
  -Mode analyses `
  -DeleteAnalysesOlderThanDays 180

# Safety gates for deletion:
# 1. SARIF must be archived locally
# 2. Analysis must be marked deletable (manual review required)
# 3. Dry-run logs before actual deletion
```

### Notifications Archiver

**Basic Usage:**
```powershell
# Archive only
pwsh BRAV/SCPT/sec-archiver/run-notifications.ps1 -ChunkSize 500

# Archive + mark as read (requires PAT classic)
pwsh BRAV/SCPT/sec-archiver/run-notifications.ps1 -ChunkSize 500 -MarkRead

# Dry run
pwsh BRAV/SCPT/sec-archiver/run-notifications.ps1 -ChunkSize 50 -DryRun
```

**Advanced Options:**
```powershell
# Custom chunk range
pwsh BRAV/SCPT/sec-archiver/run-notifications.ps1 `
  -ChunkOffset 100 `
  -ChunkSize 200

# Rate limiting (default: 2.0 GET, 1.0 mutation)
pwsh BRAV/SCPT/sec-archiver/run-notifications.ps1 `
  -ChunkSize 500 `
  -GetQps 2.0 `
  -MarkReadQps 1.0

# Filter by repository
pwsh BRAV/SCPT/sec-archiver/run-notifications.ps1 `
  -ChunkSize 500 `
  -FilterRepo "MoneyCat-inc/otel-ops-pack"
```

### Index Generator

```powershell
# Rebuild all indexes from local artifacts
pwsh BRAV/SCPT/sec-archiver/generate-security-index.ps1

# No API calls - pure disk scan
# Regenerates:
# - docs/BossCat/security/INDEX_ALERTS.jsonl
# - docs/BossCat/security/INDEX_ANALYSES.jsonl
# - docs/BossCat/notifications/INDEX.jsonl
```

---

## Parameters Reference

### run-security.ps1

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `Owner` | string | *required* | GitHub organization/owner |
| `Repo` | string | *required* | Repository name |
| `Mode` | enum | `alerts+analyses` | `alerts`, `analyses`, or `alerts+analyses` |
| `ChunkOffset` | int | `0` | Starting index for pagination |
| `ChunkSize` | int | `1000` | Number of items per run |
| `DryRun` | switch | `false` | Simulate without writes |
| `DeleteAnalysesOlderThanDays` | int | `-1` | Delete analyses older than N days (gated) |
| `GetQps` | double | `2.0` | Rate limit for GET requests |
| `MutateQps` | double | `1.0` | Rate limit for DELETE requests |
| `OutRoot` | string | `docs/BossCat/security` | Output directory |
| `EvidenceRoot` | string | `CHAR/EVID/security` | Evidence logs directory |
| `Token` | string | `$env:GITHUB_TOKEN` | GitHub token (or use gh CLI) |
| `IncludeDismissed` | switch | `true` | Include dismissed alerts |
| `IncludeFixed` | switch | `false` | Include fixed alerts |

### run-notifications.ps1

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ChunkOffset` | int | `0` | Starting index for pagination |
| `ChunkSize` | int | `1000` | Number of threads per run |
| `DryRun` | switch | `false` | Simulate without writes |
| `MarkRead` | switch | `false` | Mark archived threads as read (requires PAT) |
| `GetQps` | double | `2.0` | Rate limit for GET requests |
| `MarkReadQps` | double | `1.0` | Rate limit for mark-read mutations |
| `OutRoot` | string | `docs/BossCat/notifications` | Output directory |
| `EvidenceRoot` | string | `CHAR/EVID/notifications` | Evidence logs directory |
| `Token` | string | `$env:GITHUB_TOKEN` | GitHub token (PAT classic for mark-read) |
| `FilterRepo` | string | `null` | Filter by repository (e.g., "owner/repo") |

---

## Artifacts Structure

### Security Alerts

```
docs/BossCat/security/
├── INDEX_ALERTS.jsonl              # JSONL index (append-only)
├── INDEX_ALERTS.schema.json        # JSON schema for index
├── alerts/
│   └── YYYY/MM/
│       └── alert-{number}.md       # Markdown summary
└── data/alerts/
    └── YYYY/MM/
        └── alert-{number}.json     # Full JSON payload
```

### Security Analyses

```
docs/BossCat/security/
├── INDEX_ANALYSES.jsonl            # JSONL index (append-only)
├── INDEX_ANALYSES.schema.json      # JSON schema for index
├── analyses/
│   └── YYYY/MM/
│       └── analysis-{id}.sarif.json  # SARIF file (standard format)
└── data/analyses/
    └── YYYY/MM/
        └── analysis-{id}.json      # Metadata JSON
```

### Notifications

```
docs/BossCat/notifications/
├── INDEX.jsonl                     # JSONL index (append-only)
├── INDEX.schema.json               # JSON schema for index
└── threads/
    └── YYYY/MM/
        ├── thread-{id}.json        # Full thread JSON
        └── thread-{id}.md          # Human-readable Markdown
```

### Evidence Logs

```
CHAR/EVID/security/
├── LEDGER.jsonl                    # Operation ledger (append-only)
└── METRICS.jsonl                   # Metrics per run

CHAR/EVID/notifications/
├── LEDGER.jsonl                    # Operation ledger (append-only)
└── METRICS.jsonl                   # Metrics per run
```

---

## Index Schemas

### INDEX_ALERTS.jsonl

```json
{
  "number": 123,
  "state": "open",
  "severity": "high",
  "created_at": "2025-01-15T10:00:00Z",
  "updated_at": "2025-01-15T12:00:00Z",
  "dismissed_at": null,
  "dismissed_by": null,
  "dismissed_reason": null,
  "rule_id": "js/sql-injection",
  "tool": "CodeQL",
  "archived_at": "2025-01-15T12:30:00Z",
  "json_path": "data/alerts/2025/01/alert-123.json",
  "md_path": "alerts/2025/01/alert-123.md"
}
```

### INDEX_ANALYSES.jsonl

```json
{
  "id": 456789,
  "commit_sha": "abc123...",
  "ref": "refs/heads/main",
  "created_at": "2025-01-15T10:00:00Z",
  "tool": "CodeQL",
  "archived_at": "2025-01-15T12:30:00Z",
  "sarif_path": "analyses/2025/01/analysis-456789.sarif.json",
  "json_path": "data/analyses/2025/01/analysis-456789.json"
}
```

### INDEX.jsonl (Notifications)

```json
{
  "id": "789012",
  "subject": "Issue comment: Bug in login flow",
  "reason": "mention",
  "unread": false,
  "updated_at": "2025-01-15T10:00:00Z",
  "repository": "MoneyCat-inc/otel-ops-pack",
  "archived_at": "2025-01-15T12:30:00Z",
  "json_path": "threads/2025/01/thread-789012.json",
  "md_path": "threads/2025/01/thread-789012.md"
}
```

---

## Authentication

### Option 1: GitHub CLI (Recommended)

```bash
# Authenticate with gh CLI (easiest)
gh auth login

# Verify authentication
gh auth status

# Scripts will automatically use gh CLI if available
```

### Option 2: Personal Access Token

```bash
# Classic token (required for notifications mark-read)
# Scopes: repo, security_events, notifications

# Set environment variable
$env:GITHUB_TOKEN = "ghp_..."

# Or pass as parameter
pwsh run-security.ps1 -Owner ... -Repo ... -Token "ghp_..."
```

**Token Scopes Required:**
- `repo` - Full repository access
- `security_events` - Code scanning alerts (read/write)
- `notifications` - Mark notifications as read (classic token only)

---

## Rate Limiting

### Default QPS

| Operation | Default QPS | Description |
|-----------|-------------|-------------|
| GET | 2.0 | API reads (alerts, analyses, notifications) |
| DELETE | 1.0 | Delete analyses (destructive) |
| Mark-Read | 1.0 | Mark notifications as read |

### Custom Rate Limits

```powershell
# Conservative (slow but safe)
-GetQps 1.0 -MutateQps 0.5

# Aggressive (fast but risky for rate limits)
-GetQps 5.0 -MutateQps 2.0

# Default (balanced)
-GetQps 2.0 -MutateQps 1.0
```

**GitHub Rate Limits:**
- Authenticated: 5,000 requests/hour (~1.39/sec)
- Code Scanning: 1,000 requests/hour (~0.28/sec)
- Our defaults (2.0 GET, 1.0 mutate) stay well within limits

---

## Safety Features

### Dry Run Mode

```bash
# Always test first with dry run
pnpm sec:archive:dry
pnpm notify:archive:dry
```

**Dry run behavior:**
- ✅ Fetches data from API
- ✅ Logs what would be written
- ❌ No disk writes
- ❌ No mutations (delete, mark-read)

### Delete Safety Gates

**Analysis deletion requires:**
1. ✅ SARIF archived locally (`analyses/YYYY/MM/analysis-{id}.sarif.json`)
2. ✅ Analysis marked as deletable (manual review)
3. ✅ Age threshold met (`-DeleteAnalysesOlderThanDays`)
4. ✅ Dry-run logs before actual deletion

```powershell
# Safe deletion (180 days)
pwsh run-security.ps1 -Owner ... -Repo ... -Mode analyses `
  -DeleteAnalysesOlderThanDays 180
```

**Manual review process:**
1. Archive analyses first: `pnpm sec:archive:analyses`
2. Review archived SARIFs: `docs/BossCat/security/analyses/`
3. Mark deletable: Add `"deletable": true` to analysis metadata
4. Run delete: `pnpm sec:delete-old`

---

## Common Workflows

### Daily Security Archive

```bash
# 1. Archive new alerts (incremental)
pnpm sec:archive:alerts

# 2. Archive new analyses
pnpm sec:archive:analyses

# 3. Rebuild indexes
pnpm sec:index
```

### Weekly Notifications Cleanup

```bash
# 1. Dry run to preview
pnpm notify:archive:dry

# 2. Archive + mark as read (requires PAT classic)
pnpm notify:archive:mark

# 3. Verify in GitHub notifications UI
```

### Monthly Security Audit

```bash
# 1. Full archive (alerts + analyses)
pnpm sec:archive:full

# 2. Review high-severity alerts
cat docs/BossCat/security/INDEX_ALERTS.jsonl | grep '"severity":"high"'

# 3. Review recent analyses
cat docs/BossCat/security/INDEX_ANALYSES.jsonl | tail -n 20

# 4. Delete old analyses (180+ days)
pnpm sec:delete-old
```

### Disaster Recovery

```bash
# Rebuild indexes from local artifacts (no API calls)
pnpm sec:index

# Regenerates all JSONL indexes from:
# - docs/BossCat/security/data/alerts/**/*.json
# - docs/BossCat/security/data/analyses/**/*.json
# - docs/BossCat/notifications/threads/**/*.json
```

---

## Troubleshooting

### Authentication Errors

```
ERROR: Missing GITHUB_TOKEN and gh CLI not available
```

**Solution:**
```bash
# Option 1: Use gh CLI
gh auth login

# Option 2: Set token
$env:GITHUB_TOKEN = "ghp_..."
```

### Rate Limit Errors

```
ERROR: API rate limit exceeded
```

**Solution:**
```powershell
# Reduce QPS
-GetQps 1.0 -MutateQps 0.5

# Or wait for rate limit reset
gh api /rate_limit
```

### Missing SARIF for Deletion

```
ERROR: Cannot delete analysis - SARIF not archived
```

**Solution:**
```bash
# Archive analyses first
pnpm sec:archive:analyses

# Then try deletion
pnpm sec:delete-old
```

### Notifications Mark-Read Fails

```
ERROR: mark-read requires PAT classic with notifications scope
```

**Solution:**
1. Create PAT classic: https://github.com/settings/tokens
2. Scopes: `repo`, `notifications`
3. Set token: `$env:GITHUB_TOKEN = "ghp_..."`

---

## Performance Tips

### Chunking Strategy

```powershell
# Small chunks (fast iteration, many runs)
-ChunkSize 100

# Medium chunks (balanced)
-ChunkSize 500

# Large chunks (fewer runs, slower per-run)
-ChunkSize 1000
```

### Incremental Archives

```powershell
# First run: Archive everything
pnpm sec:archive:full

# Subsequent runs: Smaller chunks for new items
pnpm sec:archive -ChunkSize 200
```

### Parallel Execution

```powershell
# Alerts + analyses can run in parallel (different endpoints)
Start-Job { pnpm sec:archive:alerts }
Start-Job { pnpm sec:archive:analyses }

# Wait for completion
Get-Job | Wait-Job
```

---

## ECRR Compliance

All archiver operations follow **ECRR methodology**:

### Examine
- Fetch alerts, analyses, notifications from GitHub API
- Log current state to evidence ledgers

### Clean
- Archive to local-first storage (docs/BossCat/)
- Normalize to JSONL indexes with schemas
- Mark notifications as read (optional)

### Report
- Evidence logs: `CHAR/EVID/{security,notifications}/`
- Metrics per run: operations, items, duration
- JSONL indexes for querying

### Role
- **Authority**: BossCat OEM | Security Conveyor
- **Evidence**: Append-only ledgers
- **Traceability**: Full audit trail in Git

---

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Security Archive

on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM daily
  workflow_dispatch:

jobs:
  archive:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: pnpm install
      
      - name: Archive security alerts
        run: pnpm sec:archive:alerts
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Archive analyses
        run: pnpm sec:archive:analyses
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Rebuild indexes
        run: pnpm sec:index
      
      - name: Commit archives
        run: |
          git config user.name "BossCat Security Bot"
          git config user.email "bosscat@example.com"
          git add docs/BossCat/security/ CHAR/EVID/security/
          git commit -m "docs(security): Daily archive [skip ci]" || true
          git push
```

---

## Related Documentation

- **BossCat Charter**: `docs/BossCat/AGENTS.md`
- **ECRR Methodology**: `docs/ecrr/ECRR_REPORTS/`
- **Security Workflows**: `.github/workflows/`
- **Index Schemas**: `docs/BossCat/security/*.schema.json`, `docs/BossCat/notifications/*.schema.json`

---

**Authority**: BossCat OEM  
**Status**: Production-ready  
**Last Updated**: 2025-10-15

🐾 **BossCat Security Conveyor — Local-First, Evidence-Based**

