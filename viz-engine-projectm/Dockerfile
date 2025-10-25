FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Base deps (without nodejs/npm - will install from NodeSource)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git build-essential cmake pkg-config \
    xvfb x11-apps xdotool imagemagick ffmpeg \
    libglu1-mesa-dev mesa-utils libgl1-mesa-dri \
    pulseaudio pulseaudio-utils libpulse0 \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18.x from NodeSource (Ubuntu's nodejs is too old)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# --- Build libprojectM + SDL frontend from source
WORKDIR /opt/build
RUN git clone --depth=1 https://github.com/projectM-visualizer/projectm.git
WORKDIR /opt/build/projectm
# Initialize submodules for vendored dependencies
RUN git submodule update --init --recursive || true
# Add missing build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsdl2-dev libglm-dev libpulse-dev && rm -rf /var/lib/apt/lists/*
# Configure and build
RUN cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SDL_UI=ON \
    -DENABLE_PULSEAUDIO=ON \
    -DENABLE_JACK=OFF \
    -DENABLE_GLES=OFF \
    -DENABLE_SYSTEM_GLM=ON \
 && cmake --build build -j$(nproc) \
 && cmake --install build \
 && cp build/src/sdl-test-ui/projectM-Test-UI /usr/local/bin/projectMSDL

# App
WORKDIR /app
COPY server.js ./server.js
COPY brightness-guard.js ./brightness-guard.js
COPY pm-run.sh ./pm-run.sh
COPY pm-settings.ini ./pm-settings.ini
COPY pm-audio-bridge.cpp ./pm-audio-bridge.cpp
RUN npm init -y && npm install --save express && npm ls
RUN chmod +x /app/pm-run.sh

# Gate #013B: Compile native audio bridge
RUN g++ -O2 -std=c++17 /app/pm-audio-bridge.cpp -o /usr/local/bin/pm-audio-bridge \
 && chmod +x /usr/local/bin/pm-audio-bridge

# Gate #013C Job A: Compile synthetic audio test (standalone, no projectM deps)
COPY audio-test.cpp ./
RUN g++ -O2 -std=c++17 audio-test.cpp -o /usr/local/bin/audio-test \
 && chmod +x /usr/local/bin/audio-test

# Gate #013C Job B: Compile integration test with injector components
COPY audio-injector.hpp audio-injector.cpp ./
COPY projectm-injector.hpp projectm-injector.cpp ./
COPY audio-integration-test.cpp ./
RUN g++ -O2 -std=c++17 -c audio-injector.cpp -o audio-injector.o \
 && g++ -O2 -std=c++17 -c projectm-injector.cpp -o projectm-injector.o \
 && g++ -O2 -std=c++17 audio-integration-test.cpp audio-injector.o projectm-injector.o -o /usr/local/bin/audio-integration-test \
 && chmod +x /usr/local/bin/audio-integration-test

# Presets directory (bind mount at runtime as well)
RUN mkdir -p /presets
ENV PRESET_DIR=/presets
ENV WIDTH=1920 HEIGHT=1080 FPS=30 DISPLAY=:99 PROJECTM_BIN=projectMSDL

EXPOSE 7020
ENTRYPOINT ["/app/pm-run.sh"]

