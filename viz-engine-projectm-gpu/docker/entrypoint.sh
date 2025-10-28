#!/usr/bin/env bash
# entrypoint.sh - GPU-accelerated ProjectM with VirtualGL
#
# ARCHITECTURE:
#   1. Start Xvfb :99 (2D virtual X server for app)
#   2. Verify host GPU X server :0 is accessible
#   3. Launch ProjectM with vglrun (3D calls → GPU)
#
# ENVIRONMENT:
#   DISPLAY=:99        (2D X server for ProjectM window)
#   VGL_DISPLAY=:0     (GPU X server for 3D rendering)
#   PM_WIDTH, PM_HEIGHT, PM_FPS, PM_PRESET_DIR, PM_FIFO
#
# Authority: BossCat OEM | Executor: Cursor{Implementer}

set -e

echo "[projectm-gpu] ╔═══════════════════════════════════════════════════╗"
echo "[projectm-gpu] ║  ProjectM GPU Engine - VirtualGL Accelerated  ║"
echo "[projectm-gpu] ╚═══════════════════════════════════════════════════╝"
echo ""

# Default environment
export DISPLAY="${DISPLAY:-:99}"
export VGL_DISPLAY="${VGL_DISPLAY:-:0}"
export PM_WIDTH="${PM_WIDTH:-1280}"
export PM_HEIGHT="${PM_HEIGHT:-720}"
export PM_FPS="${PM_FPS:-30}"
export PM_PRESET_DIR="${PM_PRESET_DIR:-/app/presets}"
export PM_FIFO="${PM_FIFO:-/dev/shm/md3.pcm}"

echo "[projectm-gpu] Configuration:"
echo "  DISPLAY (2D):        $DISPLAY"
echo "  VGL_DISPLAY (3D/GPU): $VGL_DISPLAY"
echo "  Resolution:          ${PM_WIDTH}x${PM_HEIGHT} @ ${PM_FPS} FPS"
echo "  Presets:             $PM_PRESET_DIR"
echo "  Audio FIFO:          $PM_FIFO"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: Start Xvfb (2D virtual X server)
# ─────────────────────────────────────────────────────────────────────────────
echo "[projectm-gpu] [1/4] Starting Xvfb on $DISPLAY..."
Xvfb "$DISPLAY" \
  -screen 0 "${PM_WIDTH}x${PM_HEIGHT}x24" \
  +extension GLX \
  +render \
  -noreset \
  -nolisten tcp \
  &
XVFB_PID=$!
sleep 2

if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
  echo "[projectm-gpu] ❌ ERROR: Xvfb failed to start on $DISPLAY"
  exit 1
fi
echo "[projectm-gpu] ✅ Xvfb running (PID: $XVFB_PID)"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Verify GPU X server accessibility
# ─────────────────────────────────────────────────────────────────────────────
echo "[projectm-gpu] [2/4] Verifying GPU X server $VGL_DISPLAY..."
if ! timeout 5 xdpyinfo -display "$VGL_DISPLAY" >/dev/null 2>&1; then
  echo "[projectm-gpu] ⚠️  WARNING: Cannot connect to GPU X server $VGL_DISPLAY"
  echo "[projectm-gpu]     Ensure host has headless Xorg running on :0"
  echo "[projectm-gpu]     See: docs/gpu/RUN_AND_VERIFY.md"
  echo "[projectm-gpu]     Falling back to Mesa software rendering..."
  USE_VGL=0
else
  echo "[projectm-gpu] ✅ GPU X server accessible"
  USE_VGL=1
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Verify GPU rendering with VirtualGL
# ─────────────────────────────────────────────────────────────────────────────
if [ "$USE_VGL" -eq 1 ]; then
  echo "[projectm-gpu] [3/4] Testing GPU rendering with VirtualGL..."
  if command -v vglrun >/dev/null 2>&1; then
    echo "[projectm-gpu] OpenGL Info (via VirtualGL):"
    vglrun -d "$VGL_DISPLAY" glxinfo -B 2>/dev/null | grep -E 'OpenGL vendor|OpenGL renderer|OpenGL version' || echo "  (glxinfo unavailable)"
    echo ""
  else
    echo "[projectm-gpu] ⚠️  vglrun not found, using direct rendering"
    USE_VGL=0
  fi
else
  echo "[projectm-gpu] [3/4] Using Mesa software rendering (no GPU)..."
  glxinfo -display "$DISPLAY" -B 2>/dev/null | grep -E 'OpenGL vendor|OpenGL renderer' || echo "  (glxinfo unavailable)"
  echo ""
fi

# ─────────────────────────────────────────────────────────────────────────────
# Step 4: Launch ProjectM
# ─────────────────────────────────────────────────────────────────────────────
echo "[projectm-gpu] [4/4] Launching ProjectM..."
echo "[projectm-gpu] Command: ${1:-projectm}"
echo ""

# Create audio FIFO
if [ ! -p "$PM_FIFO" ]; then
  mkfifo "$PM_FIFO" 2>/dev/null || true
fi

# Cleanup handler
cleanup() {
  echo ""
  echo "[projectm-gpu] Shutting down..."
  kill $XVFB_PID 2>/dev/null || true
  rm -f "$PM_FIFO" 2>/dev/null || true
  exit 0
}
trap cleanup SIGTERM SIGINT

# Launch ProjectM with or without VirtualGL
case "${1:-projectm}" in
  projectm)
    if [ "$USE_VGL" -eq 1 ]; then
      echo "[projectm-gpu] 🎮 GPU-accelerated rendering via VirtualGL"
      exec vglrun -d "$VGL_DISPLAY" \
        projectMSDL \
        --fullscreen \
        --width "$PM_WIDTH" \
        --height "$PM_HEIGHT" \
        --fps "$PM_FPS" \
        --presetPath "$PM_PRESET_DIR" \
        --audioCapture=0
    else
      echo "[projectm-gpu] 💻 Software rendering (Mesa)"
      exec projectMSDL \
        --fullscreen \
        --width "$PM_WIDTH" \
        --height "$PM_HEIGHT" \
        --fps "$PM_FPS" \
        --presetPath "$PM_PRESET_DIR" \
        --audioCapture=0
    fi
    ;;
  
  bash|sh)
    echo "[projectm-gpu] 🐚 Interactive shell mode"
    exec bash
    ;;
  
  *)
    echo "[projectm-gpu] 🔧 Custom command: $*"
    exec "$@"
    ;;
esac

