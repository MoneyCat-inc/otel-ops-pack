FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute

# Base deps (without nodejs/npm - will install from NodeSource)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git build-essential cmake pkg-config \
    xvfb x11-apps xdotool imagemagick ffmpeg \
    libglu1-mesa-dev mesa-utils libgl1-mesa-dri \
    libglvnd0 libglx0 libglx-mesa0 libglvnd-dev libgl1 \
    pulseaudio pulseaudio-utils libpulse0 \
    python3 python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 18.x from NodeSource (Ubuntu's nodejs is too old)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# --- Build libprojectM + SDL frontend from source (PR #942)
WORKDIR /opt/build
RUN git clone --depth=1 https://github.com/projectM-visualizer/projectm.git
WORKDIR /opt/build/projectm
# Fetch PR #942 head (glad-loader) from GitHub pull ref
RUN git fetch --depth=1 origin pull/942/head:pr-942 \
 && git checkout pr-942
# Initialize submodules for vendored dependencies
RUN git submodule update --init --recursive || true
# Add missing build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsdl2-dev libglm-dev libpulse-dev libx11-dev libgl1-mesa-dev && rm -rf /var/lib/apt/lists/*
# Configure and build (PR #942: projectM now uses GLAD internally, no GLEW)
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
COPY frame-timing-stabilizer.js ./frame-timing-stabilizer.js
COPY canary-deployment.js ./canary-deployment.js
COPY otlp-emitter.js ./otlp-emitter.js
COPY lib/ ./lib/
COPY package.json ./package.json
COPY pm-run.sh ./pm-run.sh
COPY pm-settings.ini ./pm-settings.ini
COPY pm-audio-bridge.cpp ./pm-audio-bridge.cpp
RUN npm install && npm ls
RUN chmod +x /app/pm-run.sh

# Gate #013B: Compile native audio bridge
RUN g++ -O2 -std=c++17 /app/pm-audio-bridge.cpp -o /usr/local/bin/pm-audio-bridge \
 && chmod +x /usr/local/bin/pm-audio-bridge

# Gate #013C: Copy audio test files first
COPY audio-injector.hpp audio-injector.cpp ./
COPY projectm-injector.hpp projectm-injector.cpp ./
COPY audio-test.cpp ./
COPY audio-integration-test.cpp ./

# Gate #013C: Compile audio components
RUN g++ -O2 -std=c++17 -c audio-injector.cpp -o audio-injector.o \
 && g++ -O2 -std=c++17 -c projectm-injector.cpp -o projectm-injector.o

# Gate #013C Job A: Compile synthetic audio test (links with audio-injector)
RUN g++ -O2 -std=c++17 audio-test.cpp audio-injector.o -o /usr/local/bin/audio-test \
 && chmod +x /usr/local/bin/audio-test

# Gate #013C Job B: Compile integration test with all components
RUN g++ -O2 -std=c++17 audio-integration-test.cpp audio-injector.o projectm-injector.o -o /usr/local/bin/audio-integration-test \
 && chmod +x /usr/local/bin/audio-integration-test

# PR #942 Migration: Copy new library integration components
COPY gl_proc_resolver.hpp gl_proc_resolver.cpp ./
COPY projectm_renderer.hpp projectm_renderer.cpp ./
COPY projectm-smoke-test.cpp ./
COPY gl_diagnostics.cpp ./
COPY CMakeLists.txt ./

# PR #942 Migration: Build library integration components
# Using CMake for proper dependency management
RUN mkdir -p /app/build && cd /app/build \
 && cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DPROJECTM_INCLUDE_DIR=/usr/local/include \
    -DPROJECTM_LIBRARY=/usr/local/lib/libprojectM.so \
 && cmake --build . -j$(nproc) \
 && cmake --install . \
 && chmod +x /usr/local/bin/projectm-smoke-test

# Presets directory (bind mount at runtime as well)
RUN mkdir -p /presets
ENV PRESET_DIR=/presets
ENV WIDTH=1920 HEIGHT=1080 FPS=30 DISPLAY=:99 PROJECTM_BIN=projectMSDL

EXPOSE 7020
ENTRYPOINT ["/app/pm-run.sh"]
