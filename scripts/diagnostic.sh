#!/usr/bin/env bash
# Wrapper: canonical diagnostic script lives under BRAV/SCPT
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$ROOT/BRAV/SCPT/diagnostic.sh" "$@"
