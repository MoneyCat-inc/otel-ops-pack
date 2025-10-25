#!/usr/bin/env bash
set -euo pipefail

: "${DISPLAY:=:99}"
: "${GEOMETRY:=1280x720}"
: "${FPS:=30}"

# Start headless X display
Xvfb "$DISPLAY" -screen 0 "${GEOMETRY}x24" -nolisten tcp >/tmp/xvfb.log 2>&1 &

# Lightweight WM for windowed GL apps
fluxbox >/tmp/fluxbox.log 2>&1 &

# Start Express server (serves /milk page and /milk.mjpg stream)
node /opt/viz/server.js

