#!/bin/bash
# ECRR Compliance Trend Monitoring Script
# This script can be run manually or scheduled via cron

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TREND_SCRIPT="$SCRIPT_DIR/visualize-ecrr-trends.ps1"
MONITOR_SCRIPT="$SCRIPT_DIR/monitor-ecrr-compliance.ps1"

echo "Starting ECRR compliance trend monitoring..."
echo "Script directory: $SCRIPT_DIR"

# Update compliance history
echo "Updating compliance history..."
pwsh -File "$MONITOR_SCRIPT"

# Generate trend visualization
echo "Generating trend visualization..."
pwsh -File "$TREND_SCRIPT"

echo "ECRR compliance trend monitoring complete!"
