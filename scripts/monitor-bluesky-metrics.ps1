# Monitor Bluesky Campaign Metrics
# Tracks engagement and growth for AntiClickbait mission

param(
    [switch]$ShowHelp
)

if ($ShowHelp) {
    Write-Host @"
Bluesky Metrics Monitoring

USAGE:
  pwsh -File scripts\monitor-bluesky-metrics.ps1

MANUAL CHECKS:
1. Visit https://bsky.app/profile/resonai.bsky.social
2. Check follower count
3. Review post engagement (likes, reposts, replies)
4. Track Starter Pack adoption

METRICS TO TRACK:
- Followers count (growth rate)
- Post engagement (avg likes/reposts per post)
- Starter Pack follows
- AntiClickbait community growth

AUTOMATION:
This script provides a manual checklist. Future automation
could use Bluesky API for programmatic metrics collection.

EVIDENCE:
- Save screenshots to docs/evidence/bluesky/
- Update docs/status/kpis.json with metrics
- Log key milestones in docs/BossCat/BOSSCAT_LOG.md

"@
    exit 0
}

Write-Host "=== Bluesky Campaign Metrics ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Manual Monitoring Checklist:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. [ ] Visit https://bsky.app/profile/resonai.bsky.social"
Write-Host "  2. [ ] Record current follower count"
Write-Host "  3. [ ] Check latest post engagement"
Write-Host "  4. [ ] Review Starter Pack adoption"
Write-Host "  5. [ ] Check for replies/mentions"
Write-Host "  6. [ ] Update docs/status/kpis.json if significant changes"
Write-Host ""
Write-Host "📁 Evidence Collection:" -ForegroundColor Yellow
Write-Host "  - Screenshots → docs/evidence/bluesky/"
Write-Host "  - Metrics → docs/status/kpis.json"
Write-Host "  - Milestones → docs/BossCat/BOSSCAT_LOG.md"
Write-Host ""
Write-Host "🔮 Future Automation:" -ForegroundColor Yellow
Write-Host "  - Bluesky API integration for programmatic metrics"
Write-Host "  - Automated follower count tracking"
Write-Host "  - Engagement rate dashboards"
Write-Host ""
Write-Host "Profile: https://bsky.app/profile/resonai.bsky.social"
Write-Host "Starter Pack: https://bsky.app/starter-pack/resonai.bsky.social/..."
Write-Host ""
Write-Host "=== Monitoring Guide Complete ===" -ForegroundColor Cyan

