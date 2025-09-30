# ECRR Orchestrator — End-to-End Processing + Dashboard

Use the orchestrator to process all ECRR reports, validate compliance, append a monitoring entry, and publish the dashboard in one command.

## Usage

```powershell
pwsh -File scripts/ecrr-process-and-publish.ps1
```

Artifacts written:
- `artifacts/ecrr-processing-summary.json`
- `artifacts/ecrr-ci-validation.json`
- `artifacts/ecrr-compliance-history.jsonl`
- `docs/dashboard/index.html`
- `docs/dashboard/ecrr-compliance-trends.html`

## Options
- `-FailOnThreshold` to fail when compliance drops below thresholds
- `-StartWebServer` to serve the dashboard via a simple HTTP server
- `-GenerateGitHubPages` to prepare assets for GitHub Pages

## Scheduling
Add this script to your automation/scheduler to refresh the dashboard periodically.

```powershell
# Example (manual run)
pwsh -File scripts/ecrr-process-and-publish.ps1 -FailOnThreshold
```

### Windows Scheduled Task
Create a nightly scheduled task at 02:00:

```powershell
# Run as Administrator
pwsh -File scripts/schedule-ecrr-orchestrator.ps1
```

This creates a scheduled task that runs the orchestrator daily at 02:00 local time.

### CI Integration
For CI/CD pipelines, use the orchestrator with `-FailOnThreshold`:

```powershell
pwsh -File scripts/ecrr-process-and-publish.ps1 -FailOnThreshold
```

The CI script (`scripts/ci-ecrr-compliance.ps1`) automatically fails on threshold violations.

## Related
- `scripts/validate-ecrr-compliance.ps1`
- `scripts/monitor-ecrr-compliance.ps1`
- `scripts/publish-ecrr-dashboard.ps1`
