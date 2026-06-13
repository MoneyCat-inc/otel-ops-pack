# Check Hub Website Links for 404 Errors
# Usage: pwsh -File scripts\check-hub-links.ps1

$base = 'https://hub.resonai.uk/'
$links = @(
    'docs/dashboards/live-metrics.html',
    'docs/BossCat/data_room_enhanced.html',
    'docs/milk-v0/public/index.html',
    'portal.html',
    'docs/status.html',
    'docs/index.html',
    'docs/anticlickbait/index.html',
    'moneycat/',
    'docs/assets/hub.css',
    'assets/hub.js',
    'favicon.svg',
    'docs/status/kpis.json',
    'docs/widgets/bluesky-latest.json',
    '.well-known/security.txt',
    'og/og-default.svg'
)
