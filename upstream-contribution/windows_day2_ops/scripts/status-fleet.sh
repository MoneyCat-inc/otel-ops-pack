#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-..}"
mapfile -t files < <(find "$ROOT" -type f -path "*/.agent/status.json" 2>/dev/null || true)

repos=0 running=0 locked=0 blocked=0 violations=0
for f in "${files[@]}"; do
  j="$(cat "$f" 2>/dev/null || echo "")"
  if [[ -n "$j" ]]; then
    repos=$((repos+1))
    state=$(jq -r '.state // ""' <<<"$j")
    v=$(jq -r '.guardrailViolations // 0' <<<"$j")
    [[ "$state" == "running" ]] && running=$((running+1))
    [[ "$state" == "paused:lock" ]] && locked=$((locked+1))
    [[ "$state" == "blocked:env" ]] && blocked=$((blocked+1))
    violations=$((violations+v))
  fi
done

jq -n \
  --arg gen "$(date -Iseconds)" \
  --argjson repos "$repos" \
  --argjson running "$running" \
  --argjson locked "$locked" \
  --argjson blocked "$blocked" \
  --argjson violations "$violations" '
  {schema:"codex-local.fleet.v1", generatedAt:$gen, repos:$repos,
   running:$running, locked:$locked, blocked:$blocked, violations:$violations}'
