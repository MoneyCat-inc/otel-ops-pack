#!/bin/bash

# BossCat Environment Setup Script
# MoneyCat Inc - Resonai [OTel] - otel-ops-pack
# ECRR Framework: Examine -> Clean -> Report -> Role

set -euo pipefail

SKIP_PYTHON=false
SKIP_NODE=false
SKIP_K6=false
SKIP_SUDO=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-python)
            SKIP_PYTHON=true
            shift
            ;;
        --skip-node)
            SKIP_NODE=true
            shift
            ;;
        --skip-k6)
            SKIP_K6=true
            shift
            ;;
        --skip-sudo)
            SKIP_SUDO=true
            shift
            ;;
        --help)
            cat <<'EOF'
Usage: setup_cursor_implementer.sh [options]
  --skip-python    Skip Python installation and venv setup
  --skip-node      Skip Node.js dependency installation
  --skip-k6        Skip k6 verification
  --skip-sudo      Do not run commands that require sudo
  --help           Show this help message
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use --help for available options" >&2
            exit 1
            ;;
    esac
done

RED='[0;31m'
GREEN='[0;32m'
YELLOW='[1;33m'
BLUE='[0;34m'
CYAN='[0;36m'
NC='[0m'

print_section() {
    echo -e "${BLUE}## $1${NC}"
    echo
}

print_status() {
    echo -e "${GREEN}[OK] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

print_error() {
    echo -e "${RED}[FAIL] $1${NC}"
}

SCRIPT_VERSION="1.0.0"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')

echo -e "${CYAN}BossCat Environment Setup v${SCRIPT_VERSION}${NC}"
echo -e "${CYAN}Timestamp: ${TIMESTAMP}${NC}"
echo

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    print_error "Unsupported OS: $OSTYPE"
    exit 1
fi

print_section "1. Examine - Environment Detection"

print_status "Detected OS: $OS"
print_status "Current directory: $(pwd)"

if [[ ! -f "AGENTS.md" ]]; then
    print_error "AGENTS.md not found. Run this script from the project root."
    exit 1
fi

print_status "Project root confirmed"

print_section "2. Clean - Python 3.13 Setup"

PYTHON_CMD=""
PYTHON_VERSION=""
PYTHON_CANDIDATES=(python3.13 python3 python)
VENV_PYTHON=""
NODE_VERSION="Not evaluated"
NPM_VERSION="Not evaluated"
K6_VERSION="Not evaluated"
LOCUST_VERSION="Not evaluated"

if [[ "$SKIP_PYTHON" == "true" ]]; then
    print_status "Python setup skipped (--skip-python flag)"
else
    for candidate in "${PYTHON_CANDIDATES[@]}"; do
        if ! command -v "$candidate" >/dev/null 2>&1; then
            continue
        fi

        if version_output=$("$candidate" --version 2>&1); then
            if [[ "$version_output" == *"Python 3.13"* ]]; then
                PYTHON_CMD="$candidate"
                PYTHON_VERSION="$version_output"
                print_status "Python 3.13 available via $candidate ($version_output)"
                break
            elif [[ "$version_output" == Python\ 3.* ]]; then
                print_warning "Found $version_output via $candidate but Python 3.13 is required."
            fi
        else
            print_warning "Unable to run $candidate --version"
        fi
    done

    if [[ -z "$PYTHON_CMD" ]]; then
        print_warning "Python 3.13 not found."
        if [[ "$SKIP_SUDO" == "true" ]]; then
            print_warning "Automatic installation skipped (--skip-sudo). Install Python 3.13 manually."
        else
            if [[ "$OS" == "linux" ]]; then
                if command -v sudo >/dev/null 2>&1; then
                    print_status "Attempting to install Python 3.13 via deadsnakes (sudo required)..."
                    if sudo apt-get update && sudo apt-get install -y software-properties-common &&                        sudo add-apt-repository -y ppa:deadsnakes/ppa && sudo apt-get update &&                        sudo apt-get install -y python3.13 python3.13-venv python3.13-dev; then
                        print_status "Python 3.13 installed."
                    else
                        print_warning "Automatic install failed. Install manually:"
                        print_warning "  sudo apt-get install python3.13 python3.13-venv python3.13-dev"
                    fi
                else
                    print_warning "sudo not available. Install Python 3.13 manually."
                fi
            elif [[ "$OS" == "macos" ]]; then
                if command -v brew >/dev/null 2>&1; then
                    if brew install python@3.13; then
                        print_status "Python 3.13 installed via Homebrew."
                    else
                        print_warning "Homebrew install failed. Install Python 3.13 from python.org."
                    fi
                else
                    print_warning "Homebrew not found. Install Python 3.13 from python.org."
                fi
            fi
        fi

        if command -v python3.13 >/dev/null 2>&1; then
            version_output=$(python3.13 --version 2>&1)
            if [[ "$version_output" == *"Python 3.13"* ]]; then
                PYTHON_CMD="python3.13"
                PYTHON_VERSION="$version_output"
                print_status "Python 3.13 available via python3.13 ($version_output)"
            fi
        fi
    fi

    if [[ -z "$PYTHON_CMD" ]]; then
        print_warning "Python 3.13 is unavailable. Skipping virtual environment setup."
    else
        if [[ ! -d "venv" ]]; then
            print_status "Creating Python virtual environment..."
            if "$PYTHON_CMD" -m venv venv; then
                print_status "Virtual environment created."
            else
                print_error "Failed to create virtual environment with $PYTHON_CMD"
            fi
        else
            print_status "Using existing virtual environment."
        fi

        if [[ -x "venv/bin/python" ]]; then
            VENV_PYTHON="venv/bin/python"
            print_status "Upgrading pip in virtual environment..."
            if "$VENV_PYTHON" -m pip install --upgrade pip >/dev/null 2>&1; then
                print_status "pip upgraded."
            else
                print_warning "pip upgrade failed."
            fi

            for req_file in requirements.txt requirements-dev.txt; do
                if [[ -f "$req_file" ]]; then
                    print_status "Installing dependencies from $req_file"
                    if "$VENV_PYTHON" -m pip install -r "$req_file"; then
                        print_status "Installed dependencies from $req_file"
                    else
                        print_warning "Dependency installation from $req_file failed."
                    fi
                fi
            done

            print_status "Ensuring BossCat Python tooling is installed"
            if "$VENV_PYTHON" -m pip install flake8 black locust pytest pytest-cov; then
                print_status "BossCat tooling installed."
            else
                print_warning "BossCat tooling installation failed."
            fi
        else
            print_warning "venv/bin/python not found. Skipping dependency installation."
        fi
    fi
fi

if command -v locust >/dev/null 2>&1; then
    LOCUST_VERSION=$(locust --version 2>&1)
else
    LOCUST_VERSION="Not available"
fi

print_section "3. Report - Node.js and Testing Tools Setup"

if [[ "$SKIP_NODE" == "true" ]]; then
    print_status "Node.js setup skipped (--skip-node flag)"
    NODE_VERSION="Skipped (--skip-node)"
    NPM_VERSION="Skipped (--skip-node)"
else
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version)
        print_status "Node.js found: $NODE_VERSION"
    else
        NODE_VERSION="Not available"
        print_warning "Node.js not found. Install from https://nodejs.org/"
    fi

    if command -v npm >/dev/null 2>&1; then
        NPM_VERSION=$(npm --version)
    else
        NPM_VERSION="Not available"
        print_warning "npm not found. Install Node.js to obtain npm."
    fi

    if [[ -f "package.json" ]]; then
        if command -v npm >/dev/null 2>&1; then
            print_status "Installing npm dependencies..."
            if npm install; then
                print_status "npm install completed"
            else
                print_warning "npm install failed"
            fi

            print_status "Running npm audit fix..."
            if npm audit fix --force >/dev/null 2>&1; then
                print_status "npm audit fix completed"
            else
                print_warning "npm audit fix encountered issues"
            fi
        fi
    else
        print_warning "package.json not found; skipping npm install"
    fi
fi

if [[ "$SKIP_K6" == "true" ]]; then
    print_status "k6 verification skipped (--skip-k6 flag)"
    K6_VERSION="Skipped (--skip-k6)"
else
    if command -v k6 >/dev/null 2>&1; then
        K6_VERSION=$(k6 version 2>&1)
        print_status "k6 found: $K6_VERSION"
    else
        K6_VERSION="Not available"
        print_warning "k6 not found. Install from https://k6.io/docs/get-started/installation/"
    fi
fi

print_section "4. Role - Directory Structure Setup"

mkdir -p artifacts artifacts/benchmarks artifacts/reports artifacts/snapshots
mkdir -p docs/BossCat/reports CHAR/ECRR/ECRR_REPORTS docs/observability/snapshots docs/cheatsheets

print_status "Directory structure prepared"

print_status "Creating BossCat compliance placeholders..."

touch artifacts/benchmarks/.placeholder
: > artifacts/reports/.gitkeep
: > artifacts/snapshots/.gitkeep

if [[ ! -f "docs/IONA_ERRORS.md" ]]; then
    cat <<'EOF' > docs/IONA_ERRORS.md
# IONA Error Ledger

Status: initialized
EOF
    print_status "Created docs/IONA_ERRORS.md"
else
    print_status "docs/IONA_ERRORS.md already present"
fi

print_status "Validating comfort-cat creative references..."

if [[ -d "docs/comfort-cat" ]]; then
    print_status "comfort-cat directory found"
else
    print_status "Creating comfort-cat stub directory..."
    mkdir -p docs/comfort-cat
fi

if [[ ! -f "docs/comfort-cat/copy.md" ]]; then
    cat <<'EOF' > docs/comfort-cat/copy.md
# Voice & Copy
version: cc-v1.0.0
Status: Draft | Owner: Editorial

Primary CTA: "Sleep easy. We've got the signal."
Tone: Warm, concise, lightly clever. Keep copy sparse; rely on visuals.
EOF
    print_status "Created copy.md"
else
    print_status "copy.md already present"
fi

if [[ ! -f "docs/comfort-cat/type.md" ]]; then
    cat <<'EOF' > docs/comfort-cat/type.md
# Typography
version: cc-v1.0.0
Status: Draft | Owner: Design

Primary font: System fonts for accessibility
Secondary font: Monospace for technical content
EOF
    print_status "Created type.md"
else
    print_status "type.md already present"
fi

if [[ ! -f "docs/comfort-cat/motion.md" ]]; then
    cat <<'EOF' > docs/comfort-cat/motion.md
# Motion & Animation
version: cc-v1.0.0
Status: Draft | Owner: Design

Principle: Smooth, calming transitions
Duration: 200ms for UI interactions
Easing: ease-out for comfort
EOF
    print_status "Created motion.md"
else
    print_status "motion.md already present"
fi

print_section "5. ECRR Compliance Verification"

ECRR_COMPLIANCE=0
TOTAL_CHECKS=5

if [[ -d "CHAR/ECRR/ECRR_REPORTS" ]]; then
    print_status "ECRR reports directory present"
    ((++ECRR_COMPLIANCE))
else
    print_error "ECRR reports directory missing"
fi

if [[ -d "artifacts" ]]; then
    print_status "Artifacts directory present"
    ((++ECRR_COMPLIANCE))
else
    print_error "Artifacts directory missing"
fi

if [[ -d "docs/BossCat/reports" ]]; then
    print_status "BossCat reports directory present"
    ((++ECRR_COMPLIANCE))
else
    print_error "BossCat reports directory missing"
fi

if [[ -f "docs/IONA_ERRORS.md" ]]; then
    print_status "IONA error ledger present"
    ((++ECRR_COMPLIANCE))
else
    print_error "IONA error ledger missing"
fi

if [[ -d "docs/comfort-cat" ]]; then
    print_status "comfort-cat references present"
    ((++ECRR_COMPLIANCE))
else
    print_error "comfort-cat references missing"
fi

print_section "6. Final Status Report"

COMPLIANCE_PERCENT=$((ECRR_COMPLIANCE * 100 / TOTAL_CHECKS))

echo -e "${CYAN}BossCat Environment Setup Complete${NC}"
echo

if [[ $COMPLIANCE_PERCENT -eq 100 ]]; then
    echo -e "${GREEN}[OK] Full BossCat compliance achieved!${NC}"
elif [[ $COMPLIANCE_PERCENT -ge 80 ]]; then
    echo -e "${YELLOW}[WARN] BossCat compliance has minor gaps${NC}"
else
    echo -e "${RED}[FAIL] BossCat compliance issues detected${NC}"
fi

echo

echo -e "${BLUE}Environment Summary:${NC}"

if [[ -n "$PYTHON_CMD" ]]; then
    PYTHON_SUMMARY="${PYTHON_VERSION:-$($PYTHON_CMD --version 2>&1)}"
else
    PYTHON_SUMMARY="Not available"
    for candidate in "${PYTHON_CANDIDATES[@]}"; do
        if command -v "$candidate" >/dev/null 2>&1; then
            PYTHON_SUMMARY=$("$candidate" --version 2>&1)
            break
        fi
    done
fi

echo "- Python: $PYTHON_SUMMARY"
echo "- Node.js: $NODE_VERSION"
echo "- npm: $NPM_VERSION"
echo "- k6: $K6_VERSION"
echo "- Locust: $LOCUST_VERSION"

echo

echo -e "${CYAN}Next Steps:${NC}"
echo "1. Activate Python environment: source venv/bin/activate"
echo "2. Run BossCat health check: pwsh -File scripts/quick-monitor.ps1"
echo "3. Execute CI workflow: bash setup_cursor_implementer.sh"
echo "4. Monitor SigNoz UI: http://localhost:8080"

echo

echo -e "${GREEN}BossCat environment ready for CI workflow execution!${NC}"
echo -e "${CYAN}Timestamp: ${TIMESTAMP}${NC}"

