# Security & Notifications Archiver

**Local-first conveyor tooling** for archiving GitHub Code Scanning alerts, analyses, and notifications.

## Quick Start

```bash
# Security alerts + analyses
pnpm sec:archive

# Notifications
pnpm notify:archive

# Full documentation
See: docs/cheatsheets/security-notifications-archiver.md
```

## Scripts

| Script | Purpose |
|--------|---------|
| `run-security.ps1` | Archive Code Scanning alerts and analyses |
| `run-notifications.ps1` | Archive GitHub notifications threads |
| `generate-security-index.ps1` | Rebuild indexes from local artifacts |

## Key Features

- ✅ **Local-first**: All artifacts stored in `docs/BossCat/`
- ✅ **JSONL indexes**: Append-only, queryable with schemas
- ✅ **SARIF preservation**: Full analysis archives for compliance
- ✅ **Evidence logs**: Complete audit trail in `CHAR/EVID/`
- ✅ **Safe deletion**: Gated analysis cleanup with archived evidence
- ✅ **Rate limiting**: Configurable QPS (default 2.0 GET, 1.0 mutate)

## Artifacts Structure

```
docs/BossCat/
├── security/
│   ├── INDEX_ALERTS.jsonl
│   ├── INDEX_ANALYSES.jsonl
│   ├── alerts/YYYY/MM/*.md
│   ├── analyses/YYYY/MM/*.sarif.json
│   └── data/
│       ├── alerts/YYYY/MM/*.json
│       └── analyses/YYYY/MM/*.json
└── notifications/
    ├── INDEX.jsonl
    └── threads/YYYY/MM/
        ├── *.json
        └── *.md

CHAR/EVID/
├── security/
│   ├── LEDGER.jsonl
│   └── METRICS.jsonl
└── notifications/
    ├── LEDGER.jsonl
    └── METRICS.jsonl
```

## Authentication

### Option 1: GitHub CLI (Recommended)
```bash
gh auth login
```

### Option 2: Personal Access Token
```powershell
$env:GITHUB_TOKEN = "ghp_..."
```

**Required scopes:**
- `repo` - Repository access
- `security_events` - Code scanning
- `notifications` - Mark as read (classic token only)

## Safety Gates

### Dry Run Mode
```bash
pnpm sec:archive:dry
pnpm notify:archive:dry
```

### Analysis Deletion
Requires:
1. SARIF archived locally
2. Manual review + deletable flag
3. Age threshold met

```bash
pnpm sec:delete-old
```

## ECRR Compliance

All operations follow **ECRR methodology**:
- **Examine**: Fetch from GitHub API
- **Clean**: Archive to local storage
- **Report**: Evidence logs + metrics
- **Role**: BossCat OEM authority

## Package Scripts

```json
{
  "sec:archive": "Archive alerts + analyses (200)",
  "sec:archive:alerts": "Alerts only",
  "sec:archive:analyses": "Analyses only (SARIF)",
  "sec:archive:full": "Full archive (500)",
  "sec:archive:dry": "Dry run (50)",
  "sec:delete-old": "Delete old analyses (180d)",
  "sec:index": "Rebuild indexes",
  "notify:archive": "Archive notifications",
  "notify:archive:mark": "Archive + mark read",
  "notify:archive:dry": "Notifications dry run"
}
```

## Related Documentation

- **Cheatsheet**: `docs/cheatsheets/security-notifications-archiver.md`
- **BossCat Charter**: `docs/BossCat/CHARTER.md`
- **ECRR Reports**: `docs/ecrr/ECRR_REPORTS/`
- **Index Schemas**: `docs/BossCat/{security,notifications}/*.schema.json`

---

**Authority**: BossCat OEM  
**Status**: Production-ready

🐾 **BossCat Security Conveyor**
