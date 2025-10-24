#!/usr/bin/env bash
# Gate #013 - ProjectM Runner with Audio
# ECRR: BossCat - PulseAudio pipe-source for audio reactivity
set -euo pipefail

# Environment
export DISPLAY=${DISPLAY:-:99}
PM_AUDIO_FIFO=${PM_AUDIO_FIFO:-/tmp/pm-audio.pcm}
PM_WIDTH=${PM_WIDTH:-1920}
PM_HEIGHT=${PM_HEIGHT:-1080}
AUDIO_PATH=${AUDIO_PATH:-pulse}

# 1) Start headless X server
echo "[pm-run] Starting Xvfb at ${DISPLAY}..."
rm -f /tmp/.X${DISPLAY#:}-lock /tmp/.X11-unix/X${DISPLAY#:}
Xvfb $DISPLAY -screen 0 ${PM_WIDTH}x${PM_HEIGHT}x24 -nolisten tcp +extension GLX +render -noreset &
sleep 2

# 2) Start PulseAudio (Path A: pipe-source)
if [ "$AUDIO_PATH" = "pulse" ]; then
  echo "[pm-run] Starting PulseAudio daemon..."
  mkdir -p /root/.config/pulse
  pulseaudio -D --exit-idle-time=-1 --log-level=error || echo "[pm-run] PulseAudio already running"
  sleep 1
  
  # Create named pipe for audio input
  echo "[pm-run] Creating audio FIFO: ${PM_AUDIO_FIFO}..."
  rm -f ${PM_AUDIO_FIFO}
  mkfifo -m 666 ${PM_AUDIO_FIFO}
  
  # Load pipe-source module (44.1kHz, stereo, s16le)
  echo "[pm-run] Loading PulseAudio pipe-source module..."
  pactl load-module module-pipe-source \
    source_name=pm_fifo \
    file=${PM_AUDIO_FIFO} \
    rate=44100 \
    channels=2 \
    format=s16le > /tmp/pa_pipe_mod.txt || echo "[pm-run] Pipe-source module load failed"
  
  # Set as default source
  pactl set-default-source pm_fifo || echo "[pm-run] Could not set default source"
  
  echo "[pm-run] PulseAudio pipe-source ready: ${PM_AUDIO_FIFO}"
fi

# 3) Launch Node API server (will spawn ProjectM as child)
echo "[pm-run] Starting API server..."
exec node /app/server.js

