#!/usr/bin/env bash
#
# BossCat Diagnostic Shell
# Collects environment information for IONA gating compliance
#
# Usage: ./scripts/diagnostic.sh [output_file]
# Output: JSON-formatted diagnostic data
#

set -euo pipefail

# Output file (default: stdout, or specify file path)
OUTPUT_FILE="${1:-/dev/stdout}"

# Initialize diagnostic data structure
DIAG_DATA='{}'

# Helper function to add field to JSON
add_field() {
    local key="$1"
    local value="$2"
    DIAG_DATA=$(echo "$DIAG_DATA" | jq --arg k "$key" --arg v "$value" '.[$k] = $v')
}

# Helper function to add nested object
add_object() {
    local key="$1"
    local value="$2"
    DIAG_DATA=$(echo "$DIAG_DATA" | jq --arg k "$key" --argjson v "$value" '.[$k] = $v')
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "🔍 BossCat Diagnostic Shell - Collecting environment information..." >&2
echo "" >&2

# ═══════════════════════════════════════════════════════════════════════
# System Information
# ═══════════════════════════════════════════════════════════════════════

echo "  → Collecting system information..." >&2

# OS detection
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="linux"
    OS_NAME=$(grep '^NAME=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "Unknown Linux")
    OS_VERSION=$(grep '^VERSION=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo "Unknown")
    KERNEL=$(uname -r)
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
    OS_NAME="macOS"
    OS_VERSION=$(sw_vers -productVersion)
    KERNEL=$(uname -r)
elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
    OS_TYPE="windows"
    OS_NAME="Windows"
    OS_VERSION=$(cmd.exe /c ver 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "Unknown")
    KERNEL="NT"
else
    OS_TYPE="unknown"
    OS_NAME="Unknown"
    OS_VERSION="Unknown"
    KERNEL=$(uname -r 2>/dev/null || echo "Unknown")
fi

add_field "os_type" "$OS_TYPE"
add_field "os_name" "$OS_NAME"
add_field "os_version" "$OS_VERSION"
add_field "kernel" "$KERNEL"

# Architecture
ARCH=$(uname -m 2>/dev/null || echo "Unknown")
add_field "architecture" "$ARCH"

# Hostname
HOSTNAME=$(hostname 2>/dev/null || echo "Unknown")
add_field "hostname" "$HOSTNAME"

# CPU information
if command_exists lscpu; then
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    CPU_CORES=$(lscpu | grep "^CPU(s):" | cut -d: -f2 | xargs)
elif command_exists sysctl; then
    CPU_MODEL=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "Unknown")
    CPU_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo "Unknown")
else
    CPU_MODEL="Unknown"
    CPU_CORES="Unknown"
fi
add_field "cpu_model" "$CPU_MODEL"
add_field "cpu_cores" "$CPU_CORES"

# Memory information
if command_exists free; then
    MEMORY_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
    MEMORY_AVAILABLE=$(free -m | awk '/^Mem:/{print $7}')
elif command_exists vm_stat; then
    MEMORY_TOTAL=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024)}')
    MEMORY_AVAILABLE="N/A"
else
    MEMORY_TOTAL="Unknown"
    MEMORY_AVAILABLE="Unknown"
fi
add_field "memory_total_mb" "$MEMORY_TOTAL"
add_field "memory_available_mb" "$MEMORY_AVAILABLE"

# Disk usage
DISK_USAGE=$(df -h . 2>/dev/null | awk 'NR==2 {print $5}' || echo "Unknown")
DISK_TOTAL=$(df -h . 2>/dev/null | awk 'NR==2 {print $2}' || echo "Unknown")
DISK_AVAILABLE=$(df -h . 2>/dev/null | awk 'NR==2 {print $4}' || echo "Unknown")
add_field "disk_usage_percent" "$DISK_USAGE"
add_field "disk_total" "$DISK_TOTAL"
add_field "disk_available" "$DISK_AVAILABLE"

# ═══════════════════════════════════════════════════════════════════════
# Tool Versions
# ═══════════════════════════════════════════════════════════════════════

echo "  → Checking installed tools..." >&2

TOOLS_JSON='{}' 

# Git
if command_exists git; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    TOOLS_JSON=$(echo "$TOOLS_JSON" | jq --arg v "$GIT_VERSION" '.git = $v')
fi

# Docker
if command_exists docker; then
    DOCKER_VERSION=$(docker --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
    TOOLS_JSON=$(echo "$TOOLS_JSON" | jq --arg v "$DOCKER_VERSION" '.docker = $v')
fi

# Docker Compose
if command_exists docker-compose; then
    DOCKER_COMPOSE_VERSION=$(docker-compose --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
    TOOLS_JSON=$(echo "$TOOLS_JSON" | jq --arg v "$DOCKER_COMPOSE_VERSION" '.docker_compose = $v')
fi

# Node.js
if command_exists node; then
    NODE_VERSION=$(node --version | sed 's/v//')
    TOOLS_JSON=$(echo "$TOOLS_JSON" | jq --arg v "$NODE_VERSION" '.node = $v')
fi

# NPM
if command_exists npm; then
    NPM_VERSION=$(npm --version)
    TOOLS_JSON=$(echo "$TOOLS_JSON" | jq --arg v "$NPM_VERSION" '.npm = $v')
fi

# PNPM
if command_exists pnpm; then
    PNPM_VERSION=$(pnpm --version)
    TOOLS_JSON=$(echo "$TOOLS_JSON" | jq --arg v "$PNPM_VERSION" '.pnpm = $v')
fi

# Python
if command_exists python3; then
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    TOOLS_JSON=$(echo "$TOOLS_JSON" | jq --arg v "$PYTHON_VERSION" '.python3 = $v')
elif command_exists python; then
    PYTHON_VERSION=$(python --version 2>&1 | awk '{print $2}')
    TOOLS_JSON=$(echo "$TOOLS_JSON" | jq --arg v "$PYTHON_VERSION" '.python = $v')
fi

# Pip
if command_exists pip3; then
    PIP_VERSION=$(pip3 --version | awk '{print $2}')
    TOOLS_JSON=$(echo "$TOOLS_JSON" | jq --arg v "$PIP_VERSION" '.pip3 = $v')
elif command_exists pip; then
    PIP_VERSION=$(pip --version | awk '{print $2}')
    TOOLS_JSON=$(echo "$TOOLS_JSON" | jq --arg v "$PIP_VERSION" '.pip = $v')
fi

# PowerShell
if command_exists pwsh; then
    PWSH_VERSION=$(pwsh --version | grep -oP '\d+\.\d+\.\d+' | head -1)
    TOOLS_JSON=$(echo "$TOOLS_JSON" | jq --arg v "$PWSH_VERSION" '.pwsh = $v')
fi

# Playwright
if command_exists npx; then
    PLAYWRIGHT_VERSION=$(npx playwright --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "not_installed")
    TOOLS_JSON=$(echo "$TOOLS_JSON" | jq --arg v "$PLAYWRIGHT_VERSION" '.playwright = $v')
fi

# GitHub CLI
if command_exists gh; then
    GH_VERSION=$(gh --version | head -1 | awk '{print $3}')
    TOOLS_JSON=$(echo "$TOOLS_JSON" | jq --arg v "$GH_VERSION" '.gh = $v')
fi

# Gitleaks
if command_exists gitleaks; then
    GITLEAKS_VERSION=$(gitleaks version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
    TOOLS_JSON=$(echo "$TOOLS_JSON" | jq --arg v "$GITLEAKS_VERSION" '.gitleaks = $v')
fi

add_object "tools" "$TOOLS_JSON"

# ═══════════════════════════════════════════════════════════════════════
# Connectivity Checks
# ═══════════════════════════════════════════════════════════════════════

echo "  → Testing connectivity..." >&2

CONNECTIVITY_JSON='{}'

# GitHub API
if command_exists curl; then
    GITHUB_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://api.github.com/ --max-time 5 2>/dev/null || echo "000")
    CONNECTIVITY_JSON=$(echo "$CONNECTIVITY_JSON" | jq --arg s "$GITHUB_STATUS" '.github_api = $s')
fi

# NPM Registry
if command_exists curl; then
    NPM_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://registry.npmjs.org/ --max-time 5 2>/dev/null || echo "000")
    CONNECTIVITY_JSON=$(echo "$CONNECTIVITY_JSON" | jq --arg s "$NPM_STATUS" '.npm_registry = $s')
fi

# PyPI
if command_exists curl; then
    PYPI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://pypi.org/simple/ --max-time 5 2>/dev/null || echo "000")
    CONNECTIVITY_JSON=$(echo "$CONNECTIVITY_JSON" | jq --arg s "$PYPI_STATUS" '.pypi = $s')
fi

# SigNoz (local)
if command_exists curl; then
    SIGNOZ_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/api/v1/health --max-time 3 2>/dev/null || echo "000")
    CONNECTIVITY_JSON=$(echo "$CONNECTIVITY_JSON" | jq --arg s "$SIGNOZ_STATUS" '.signoz_local = $s')
fi

# OTel Collector (local HTTP)
if command_exists curl; then
    OTEL_HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5318 --max-time 3 2>/dev/null || echo "000")
    CONNECTIVITY_JSON=$(echo "$CONNECTIVITY_JSON" | jq --arg s "$OTEL_HTTP_STATUS" '.otel_collector_http = $s')
fi

add_object "connectivity" "$CONNECTIVITY_JSON"

# ═══════════════════════════════════════════════════════════════════════
# Environment Variables (non-sensitive)
# ═══════════════════════════════════════════════════════════════════════

echo "  → Collecting environment variables..." >&2

ENV_JSON='{}'

# OTel-related environment variables
for var in OTEL_EXPORTER_OTLP_ENDPOINT OTEL_SERVICE_NAME OTEL_RESOURCE_ATTRIBUTES NODE_ENV CI; do
    if [[ -n "${!var:-}" ]]; then
        ENV_JSON=$(echo "$ENV_JSON" | jq --arg k "$var" --arg v "${!var}" '.[$k] = $v')
    fi
done

add_object "environment" "$ENV_JSON"

# ═══════════════════════════════════════════════════════════════════════
# Git Information
# ═══════════════════════════════════════════════════════════════════════

echo "  → Collecting git information..." >&2

GIT_JSON='{}'

if command_exists git && git rev-parse --git-dir > /dev/null 2>&1; then
    GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
    GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    GIT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "none")
    GIT_STATUS=$(git status --porcelain 2>/dev/null | wc -l)
    
    GIT_JSON=$(echo "$GIT_JSON" | jq --arg b "$GIT_BRANCH" '.branch = $b')
    GIT_JSON=$(echo "$GIT_JSON" | jq --arg c "$GIT_COMMIT" '.commit = $c')
    GIT_JSON=$(echo "$GIT_JSON" | jq --arg r "$GIT_REMOTE" '.remote = $r')
    GIT_JSON=$(echo "$GIT_JSON" | jq --argjson s "$GIT_STATUS" '.uncommitted_changes = $s')
fi

add_object "git" "$GIT_JSON"

# ═══════════════════════════════════════════════════════════════════════
# Metadata
# ═══════════════════════════════════════════════════════════════════════

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
add_field "timestamp" "$TIMESTAMP"
add_field "diagnostic_version" "1.0.0"

# ═══════════════════════════════════════════════════════════════════════
# Output Results
# ═══════════════════════════════════════════════════════════════════════

echo "" >&2
echo "✅ Diagnostic collection complete!" >&2

# Pretty-print JSON to output file
echo "$DIAG_DATA" | jq '.' > "$OUTPUT_FILE"

if [[ "$OUTPUT_FILE" != "/dev/stdout" ]]; then
    echo "📄 Diagnostic data saved to: $OUTPUT_FILE" >&2
    echo "" >&2
    echo "Summary:" >&2
    echo "  OS: $OS_NAME $OS_VERSION" >&2
    echo "  Architecture: $ARCH" >&2
    echo "  CPU: $CPU_MODEL ($CPU_CORES cores)" >&2
    echo "  Memory: $MEMORY_TOTAL MB total" >&2
    echo "  Disk: $DISK_AVAILABLE available ($DISK_USAGE used)" >&2
fi

exit 0

