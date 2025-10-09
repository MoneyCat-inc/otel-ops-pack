#!/usr/bin/env bash
# Kustomize rollout helper
# Usage: bash BRAV/SCPT/rollout_kustomize.sh <ENV> <IMAGE>

set -euo pipefail

ENV="${1:-}"
IMAGE="${2:-}"

if [[ -z "$ENV" || -z "$IMAGE" ]]; then
    echo "❌ Usage: rollout_kustomize.sh <ENV> <IMAGE>"
    echo ""
    echo "Example:"
    echo "  bash BRAV/SCPT/rollout_kustomize.sh DEV ghcr.io/org/app:abc123"
    exit 2
fi

OVER="DELT/CONF/OVER/$ENV"

if [[ ! -d "$OVER" ]]; then
    echo "❌ No kustomize overlay found at: $OVER"
    echo "   Create overlays in DELT/CONF/OVER/ (DEV, STAG, PROD)"
    exit 2
fi

echo "🌐 Kustomize Rollout"
echo "   Environment: $ENV"
echo "   Overlay: $OVER"
echo "   Image: $IMAGE"

# Validate kustomize overlay
echo "  🔍 Validating overlay..."
if ! command -v kustomize &> /dev/null; then
    echo "  ⚠️  kustomize not installed - skipping validation"
    echo "     Install: https://kubectl.docs.kubernetes.io/installation/kustomize/"
else
    kustomize build "$OVER" >/dev/null
    echo "  ✅ Overlay validation passed"
fi

# Patch image (example - adjust to your kustomization.yaml structure)
echo "  🖼️  Patching image to: $IMAGE"

# Option 1: Use kustomize edit (requires kustomize CLI)
if command -v kustomize &> /dev/null; then
    pushd "$OVER" >/dev/null
    kustomize edit set image "app-image=$IMAGE"
    popd >/dev/null
    echo "  ✅ Image updated in kustomization.yaml"
fi

# Option 2: Direct apply (requires kubectl context)
if [[ "${APPLY_DEPLOY:-false}" == "true" ]]; then
    echo "  🚀 Applying to Kubernetes..."
    kubectl apply -k "$OVER"
    echo "  ✅ Applied to cluster"
else
    echo "  ℹ️  Dry-run mode (set APPLY_DEPLOY=true to actually deploy)"
    echo "  ℹ️  Preview:"
    kustomize build "$OVER" | head -n 30
fi

echo "✅ Rollout complete: $ENV"

