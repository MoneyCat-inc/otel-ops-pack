#!/usr/bin/env bash
set -euo pipefail

: "${DISPLAY:=:99}"
: "${GEOMETRY:=1280x720}"
: "${FPS:=30}"

# NOTE: Xvfb is started by pm-engine container
# Milk v0 connects to the shared X display at :99
# No Xvfb startup here - assumes display already exists

# Start Express server (serves /milk page and /milk.mjpg stream)
node /opt/viz/server.js

