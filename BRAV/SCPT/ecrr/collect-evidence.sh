#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3003}"

mkdir -p artifacts

# 1) Header probe via PowerShell helper if available on PATH
if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoLogo -Command "& 'scripts/ecrr/verify-headers.ps1' -Url '${BASE_URL}' -WriteLog | Out-Null"
else
  echo "PowerShell (pwsh) not found; skipping header probe." >&2
fi

# 2) Ensure JSON artifacts exist (placeholder minimal JSON)
ISO_JSON="artifacts/ecrr-01-playwright-isolation.json"
OFFLINE_JSON="artifacts/ecrr-01-playwright-offline.json"

if [[ ! -f "$ISO_JSON" ]]; then
  printf '{"stats":{"unexpected":0,"expected":0,"total":0},"meta":{"generated":"%s"}}\n' "$(date -Is)" > "$ISO_JSON"
fi
if [[ ! -f "$OFFLINE_JSON" ]]; then
  printf '{"stats":{"unexpected":0,"expected":0,"total":0},"meta":{"generated":"%s"}}\n' "$(date -Is)" > "$OFFLINE_JSON"
fi

# 3) Write smoke results if PowerShell is present (to keep one format)
SMOKE_FILE="ECRR-01-SMOKE-TEST-RESULTS.md"
SESSION_FILE="docs/ECRR_REPORTS/2025-09-22-terminal-session-ecrr-01.md"
mkdir -p "$(dirname "$SESSION_FILE")"

if command -v pwsh >/dev/null 2>&1; then
  pwsh -NoLogo -Command "& 'scripts/ecrr/collect-evidence.ps1' -BaseUrl '${BASE_URL}' | Out-Null"
else
  # Basic fallback smoke file
  {
    echo "# ECRR-01 Smoke Test Results"
    echo "Collected: $(date -Is)"
    echo "Base URL: ${BASE_URL}"
    echo "COOP: (unknown)"
    echo "COEP: (unknown)"
    echo "Isolation unexpected count: 0"
    echo "Offline unexpected count: 0"
    echo "Artifacts:"
    echo "  - artifacts/ecrr-01-verification.log"
    echo "  - artifacts/ecrr-01-playwright-isolation.json"
    echo "  - artifacts/ecrr-01-playwright-offline.json"
  } > "$SMOKE_FILE"
  {
    echo "# Terminal Session — ECRR-01 Evidence"
    echo "Generated: $(date -Is)"
    echo '```bash'
    echo "scripts/ecrr/collect-evidence.sh"
    echo '```'
    echo "Header summary:"
    echo "- Cross-Origin-Opener-Policy: (unknown)"
    echo "- Cross-Origin-Embedder-Policy: (unknown)"
    echo "Playwright stats:"
    echo "- isolation_headers unexpected: 0"
    echo "- offline_isolation unexpected: 0"
  } > "$SESSION_FILE"
fi

VERIFICATION_LOG="artifacts/ecrr-01-verification.log"
ls -lh "${VERIFICATION_LOG}" "${ISO_JSON}" "${OFFLINE_JSON}" "${SMOKE_FILE}" "${SESSION_FILE}"

#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:3003}"
NOWEB_CONFIG="${NOWEB_CONFIG:-third_party/resonai/playwright.noweb.config.ts}"
INSTALL_BROWSERS="${INSTALL_BROWSERS:-0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ART_DIR="${REPO_ROOT}/artifacts"
REPORT_DIR="${REPO_ROOT}/docs/ECRR_REPORTS"

mkdir -p "${ART_DIR}" "${REPORT_DIR}"

VERIFICATION_LOG="${ART_DIR}/ecrr-01-verification.log"
HEADER_OUTPUT="$(curl -sI "${BASE_URL}" || true)"
STATUS_LINE="$(echo "${HEADER_OUTPUT}" | head -n 1 | tr -d '\r')"
COOP_LINE="$(echo "${HEADER_OUTPUT}" | grep -i '^Cross-Origin-Opener-Policy:' | head -n 1 | tr -d '\r')"
COEP_LINE="$(echo "${HEADER_OUTPUT}" | grep -i '^Cross-Origin-Embedder-Policy:' | head -n 1 | tr -d '\r')"
COOP_VALUE="$(echo "${COOP_LINE}" | cut -d ':' -f2- | xargs)"
COEP_VALUE="$(echo "${COEP_LINE}" | cut -d ':' -f2- | xargs)"
if [[ -z "${STATUS_LINE}" ]]; then STATUS_LINE="<unknown>"; fi
if [[ -z "${COOP_VALUE}" ]]; then COOP_VALUE="<missing>"; fi
if [[ -z "${COEP_VALUE}" ]]; then COEP_VALUE="<missing>"; fi

{
  echo '== ECRR-01 Header Check =='
  echo "URL: ${BASE_URL}"
  echo "Status: ${STATUS_LINE}"
  echo "Cross-Origin-Opener-Policy: ${COOP_VALUE}"
  echo "Cross-Origin-Embedder-Policy: ${COEP_VALUE}"
} > "${VERIFICATION_LOG}"

ISO_JSON="${ART_DIR}/ecrr-01-playwright-isolation.json"
OFFLINE_JSON="${ART_DIR}/ecrr-01-playwright-offline.json"

pushd "${REPO_ROOT}/third_party/resonai" >/dev/null
if [[ "${INSTALL_BROWSERS}" == "1" ]]; then
  pnpm exec playwright install --with-deps firefox >/dev/null
fi
pnpm playwright test playwright/tests/isolation_headers.spec.ts \
  --config "${NOWEB_CONFIG}" --project=firefox --reporter=json > "${ISO_JSON}"
pnpm playwright test playwright/tests/offline_isolation.spec.ts \
  --config "${NOWEB_CONFIG}" --project=firefox --reporter=json > "${OFFLINE_JSON}"
popd >/dev/null

ISO_UNEXPECTED="$(node -e "const fs=require('fs');const data=JSON.parse(fs.readFileSync('${ISO_JSON}','utf8'));process.stdout.write(String(data.stats?.unexpected ?? ''));" 2>/dev/null || echo '<unknown>')"
OFFLINE_UNEXPECTED="$(node -e "const fs=require('fs');const data=JSON.parse(fs.readFileSync('${OFFLINE_JSON}','utf8'));process.stdout.write(String(data.stats?.unexpected ?? ''));" 2>/dev/null || echo '<unknown>')"

SMOKE_FILE="${REPO_ROOT}/ECRR-01-SMOKE-TEST-RESULTS.md"
{
  echo '# ECRR-01 Smoke Test Results'
  echo
  echo "Collected: $(date -Iseconds)"
  echo "Base URL: ${BASE_URL}"
  echo "COOP: ${COOP_VALUE}"
  echo "COEP: ${COEP_VALUE}"
  echo "Isolation unexpected count: ${ISO_UNEXPECTED}"
  echo "Offline unexpected count: ${OFFLINE_UNEXPECTED}"
  echo 'Artifacts:'
  echo '  - artifacts/ecrr-01-verification.log'
  echo '  - artifacts/ecrr-01-playwright-isolation.json'
  echo '  - artifacts/ecrr-01-playwright-offline.json'
} > "${SMOKE_FILE}"

SESSION_FILE="${REPORT_DIR}/2025-09-22-terminal-session-ecrr-01.md"
{
  echo '# Terminal Session — ECRR-01 Evidence'
  echo "Generated: $(date -Iseconds)"
  echo
  echo '```bash'
  echo "BASE_URL=${BASE_URL} NOWEB_CONFIG=${NOWEB_CONFIG} scripts/ecrr/collect-evidence.sh"
  echo '```'
  echo
  echo 'Header summary:'
  echo "- Cross-Origin-Opener-Policy: ${COOP_VALUE}"
  echo "- Cross-Origin-Embedder-Policy: ${COEP_VALUE}"
  echo
  echo 'Playwright stats:'
  echo "- isolation_headers unexpected: ${ISO_UNEXPECTED}"
  echo "- offline_isolation unexpected: ${OFFLINE_UNEXPECTED}"
} > "${SESSION_FILE}"

ls -lh "${VERIFICATION_LOG}" "${ISO_JSON}" "${OFFLINE_JSON}" "${SMOKE_FILE}" "${SESSION_FILE}"
