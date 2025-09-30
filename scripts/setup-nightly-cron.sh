#!/bin/bash
# Setup Nightly Queue Steward Diagnostics Cron Job
# Purpose: Configure cron to run nightly diagnostics automatically on Linux/macOS
# Usage: Run this script to add the cron job

set -e

# Configuration
CRON_TIME="0 2 * * *"  # 2:00 AM daily
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(dirname "$SCRIPT_DIR")"
NIGHTLY_SCRIPT="$SCRIPT_DIR/nightly-queue-diagnostics.ps1"
CRON_COMMAND="$CRON_TIME cd '$WORK_DIR' && pwsh -File '$NIGHTLY_SCRIPT' -OutputDir 'artifacts' -RetentionDays 7 >> artifacts/nightly-cron.log 2>&1"

echo "Setting up Nightly Queue Steward Diagnostics Cron Job"
echo "Working Directory: $WORK_DIR"
echo "Nightly Script: $NIGHTLY_SCRIPT"
echo "Schedule: $CRON_TIME (2:00 AM daily)"
echo ""

# Check if PowerShell is available
if ! command -v pwsh &> /dev/null; then
    echo "Error: PowerShell (pwsh) is not installed or not in PATH"
    echo "Please install PowerShell Core: https://github.com/PowerShell/PowerShell"
    exit 1
fi

# Check if the nightly diagnostics script exists
if [ ! -f "$NIGHTLY_SCRIPT" ]; then
    echo "Error: Nightly diagnostics script not found at '$NIGHTLY_SCRIPT'"
    exit 1
fi

# Create artifacts directory if it doesn't exist
mkdir -p "$WORK_DIR/artifacts"

# Create a temporary cron file
TEMP_CRON=$(mktemp)

# Get current crontab and add our job (avoiding duplicates)
(crontab -l 2>/dev/null | grep -v "nightly-queue-diagnostics.ps1"; echo "$CRON_COMMAND # Queue Steward Nightly Diagnostics") > "$TEMP_CRON"

# Install the new crontab
crontab "$TEMP_CRON"

# Clean up
rm "$TEMP_CRON"

echo "✅ Cron job created successfully!"
echo ""
echo "Cron Job Details:"
echo "  Schedule: $CRON_TIME (2:00 AM daily)"
echo "  Command: pwsh -File '$NIGHTLY_SCRIPT'"
echo "  Working Directory: $WORK_DIR"
echo "  Log File: artifacts/nightly-cron.log"
echo ""
echo "Management Commands:"
echo "  View crontab: crontab -l"
echo "  Edit crontab: crontab -e"
echo "  Remove this job: crontab -l | grep -v 'nightly-queue-diagnostics.ps1' | crontab -"
echo "  Test run: cd '$WORK_DIR' && pwsh -File '$NIGHTLY_SCRIPT' -OutputDir 'artifacts' -RetentionDays 7"
echo ""
echo "Log monitoring:"
echo "  View logs: tail -f '$WORK_DIR/artifacts/nightly-cron.log'"
echo "  Check recent runs: ls -la '$WORK_DIR/artifacts/nightly-diagnostics-summary-*.json'"
