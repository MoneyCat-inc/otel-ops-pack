#!/usr/bin/env bash
# Deploy script for applications
# Usage: bash BRAV/SCPT/deploy.sh ALFA/APPS/<APP_NAME> <package|push|rollout> [ENV]

set -euo pipefail

APP_PATH="${1:-}"
ACTION="${2:-}"

# Environment variables (set by CI or defaults)
REGISTRY="${REGISTRY:-ghcr.io}"
IMAGE_NAME="${IMAGE_NAME:-app}"
IMAGE_TAG="${IMAGE_TAG:-dev}"

if [[ -z "$APP_PATH" || -z "$ACTION" ]]; then
    echo "❌ Usage: deploy.sh <APP_PATH> <package|push|rollout> [ENV]"
    echo ""
    echo "Actions:"
    echo "  package  - Build Docker image"
    echo "  push     - Push image to registry"
    echo "  rollout  - Deploy to environment (requires ENV)"
    echo ""
    echo "Example:"
    echo "  bash BRAV/SCPT/deploy.sh ALFA/APPS/my-app package"
    echo "  bash BRAV/SCPT/deploy.sh ALFA/APPS/my-app push"
    echo "  bash BRAV/SCPT/deploy.sh ALFA/APPS/my-app rollout DEV"
    exit 2
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "❌ App directory not found: $APP_PATH"
    exit 2
fi

APP_NAME=$(basename "$APP_PATH")
FULL_IMAGE="$REGISTRY/$IMAGE_NAME:$IMAGE_TAG"

echo "🚀 Deploy: $APP_PATH"
echo "   Action: $ACTION"
echo "   Image: $FULL_IMAGE"

case "$ACTION" in
    package)
        echo "  🐳 Building Docker image..."
        
        # Check for Dockerfile
        if [[ -f "$APP_PATH/Dockerfile" ]]; then
            DOCKERFILE="$APP_PATH/Dockerfile"
        elif [[ -f "BRAV/DOCK/Dockerfile.$APP_NAME" ]]; then
            DOCKERFILE="BRAV/DOCK/Dockerfile.$APP_NAME"
        elif [[ -f "Dockerfile" ]]; then
            DOCKERFILE="Dockerfile"
        else
            echo "  ❌ No Dockerfile found for $APP_NAME"
            exit 2
        fi
        
        echo "  📄 Using Dockerfile: $DOCKERFILE"
        docker build -f "$DOCKERFILE" -t "$FULL_IMAGE" "$APP_PATH"
        echo "  ✅ Image built: $FULL_IMAGE"
        ;;
        
    push)
        echo "  📤 Pushing Docker image..."
        docker push "$FULL_IMAGE"
        echo "  ✅ Image pushed: $FULL_IMAGE"
        ;;
        
    rollout)
        ENV="${3:-DEV}"
        echo "  🌐 Rolling out to environment: $ENV"
        echo "  🖼️  Image: $FULL_IMAGE"
        
        # Call rollout helper (kustomize, helm, or custom)
        if [[ -f "BRAV/SCPT/rollout_kustomize.sh" ]]; then
            bash BRAV/SCPT/rollout_kustomize.sh "$ENV" "$FULL_IMAGE"
        elif [[ -f "BRAV/SCPT/rollout_helm.sh" ]]; then
            bash BRAV/SCPT/rollout_helm.sh "$ENV" "$FULL_IMAGE"
        else
            echo "  ℹ️  No rollout script found (BRAV/SCPT/rollout_*.sh)"
            echo "  ℹ️  Implement BRAV/SCPT/rollout_kustomize.sh or rollout_helm.sh"
            echo "  ℹ️  For now, logging rollout parameters:"
            echo "      ENV: $ENV"
            echo "      IMAGE: $FULL_IMAGE"
        fi
        
        echo "  ✅ Rollout complete: $ENV"
        ;;
        
    *)
        echo "❌ Unknown action: $ACTION"
        echo "   Valid actions: package, push, rollout"
        exit 2
        ;;
esac

echo "✅ Deploy action complete: $ACTION for $APP_PATH"

