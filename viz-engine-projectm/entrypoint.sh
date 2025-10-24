#!/usr/bin/env bash
set -euo pipefail

# 1) Start a headless X server
export DISPLAY=${DISPLAY:-:99}
# Clean up stale lockfiles
rm -f /tmp/.X${DISPLAY#:}-lock /tmp/.X11-unix/X${DISPLAY#:}
Xvfb $DISPLAY -screen 0 ${WIDTH}x${HEIGHT}x24 -nolisten tcp +extension GLX +render -noreset &
sleep 1

# 2) Start PulseAudio in user mode (simpler for containers)
mkdir -p /root/.config/pulse
pulseaudio -D --exit-idle-time=-1 --log-level=error --start || true
sleep 1

# Create named pipe for raw PCM if not present
test -p /tmp/audio.pcm || mkfifo /tmp/audio.pcm

# Load a pipe-source so anything we write to /tmp/audio.pcm becomes a microphone
pactl load-module module-pipe-source source_name=bridge \
      rate=44100 channels=2 format=s16le file=/tmp/audio.pcm > /tmp/pa_pipe_mod.txt || true
      
# Set default source to bridge for ProjectM PA frontend
pactl set-default-source bridge || true

# 3) Launch ProjectM (SDL) inside X; we'll keep it supervised by server.js
# We prefer SDL build for robust window creation under Xvfb; PA frontend feeds audio.
# server.js will (re)spawn this process when presets change.
node /app/server.js

