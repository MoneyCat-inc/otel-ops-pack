# Codex Configuration Setup Guide

## Overview
This guide documents the optimized Codex configuration for the OTel Observability Kit project, following the "Cat Nap Control Room" aesthetic for calm, efficient observability operations.

## Directory Structure

The `.codex` directory is located at `C:\Users\fubum\.codex\` and contains:

### Core Configuration Files
- **`config.toml`** - Main configuration file with TOML syntax
- **`auth.json`** - API credentials and authentication tokens (SECURE - DO NOT COMMIT)
- **`version.json`** - Automatically maintained version information
- **`internal_storage.json`** - Internal state management (DO NOT EDIT)

### Data Storage
- **`history.jsonl`** - Chat logs and session history (9 entries as of setup)
- **`sessions/`** - Previous session data (1 session file found)
- **`log/`** - Application logs (1 log file found)

## Configuration Details

### `config.toml` Features
- **Model Settings**: GPT-4 with high reasoning effort
- **Approval Policy**: `on-failure` for efficiency
- **Environment Policy**: Inherits core Windows variables, excludes secrets
- **History**: Enabled with 50 session limit, 30-day retention
- **Project Trust**: OTel project set to trusted with auto-approve
- **MCP Servers**: Playwright, filesystem, and SigNoz integration
- **ECRR Compliance**: Enabled with automated reporting
- **BossCat Integration**: Nightly automation and dashboard exports

### Security Considerations
- **`auth.json`** contains sensitive tokens and should never be committed
- Directory permissions: User has full control, secure from other users
- Environment variables exclude API keys and tokens
- Template provided at `docs/comfort-cat/codex-auth-template.json`

### MCP Server Integration
1. **Playwright**: For automated browser testing and dashboard exports
2. **Filesystem**: Project file access with root at `C:\otel`
3. **SigNoz**: Direct integration with observability stack at `localhost:8080`

## File Descriptions

### `history.jsonl`
Contains chat session logs in JSONL format:
- Session IDs for tracking conversations
- Timestamps for audit trails
- Text content of interactions
- Currently contains 9 historical entries

### `internal_storage.json`
Internal state management:
- Tracks model prompt visibility
- Maintains internal flags
- **DO NOT EDIT** - managed automatically

### `version.json`
Version tracking:
- Current version: 0.36.0
- Last checked: 2025-09-16
- Automatically updated by Codex CLI

### `sessions/` Directory
- Contains previous session data
- Can be cleared if storage space is needed
- Maintains session continuity for development

### `log/` Directory
- Application logs and debugging information
- Useful for troubleshooting Codex issues
- Rotated automatically by the system

## Integration with OTel Project

### Project Trust Levels
- **`C:\otel`**: Trusted with auto-approve for development efficiency
- **`C:\Users\fubum`**: Trusted for general operations
- **`\\?\C:\Projects\resonai`**: Trusted for cross-project work

### ECRR Compliance
- Reports directory: `C:\otel\docs\ecrr\ECRR_REPORTS`
- Snapshots directory: `C:\otel\docs\observability\snapshots`
- Automated exports enabled
- BossCat integration for nightly automation

### BossCat Integration
- Queue file: `C:\otel\.agent\state\queue.jsonl`
- Nightly automation: Enabled
- Dashboard export schedule: 2 AM UTC daily
- Executive reporting: Automated compliance tracking

## Verification Commands

To verify the configuration is working correctly:

```powershell
# Check directory structure
Get-ChildItem "$env:USERPROFILE\.codex" -Force

# Verify config syntax
codex config validate

# Test MCP server connections
codex mcp list

# Check project trust levels
codex projects list
```

## Restart Instructions

After making configuration changes:

1. **Close all Codex CLI sessions**
2. **Restart VS Code** (if using Codex extension)
3. **Verify configuration** with `codex config validate`
4. **Test functionality** with a simple command

## Security Best Practices

1. **Never commit `auth.json`** - it contains sensitive API tokens
2. **Regular token rotation** - refresh tokens periodically
3. **Monitor access logs** - check `log/` directory for anomalies
4. **Backup configuration** - keep `config.toml` in version control
5. **Environment isolation** - use different configs for dev/prod

## Troubleshooting

### Common Issues
- **Authentication errors**: Check `auth.json` token validity
- **MCP server failures**: Verify server dependencies are installed
- **Permission errors**: Ensure user has full control of `.codex` directory
- **Configuration syntax**: Use TOML validator for `config.toml`

### Support Resources
- Codex CLI documentation
- MCP server documentation
- OTel project documentation in `docs/comfort-cat/`
- BossCat troubleshooting guide

---

*This configuration follows the ECRR methodology and BossCat governance framework for the OTel Observability Kit.*
