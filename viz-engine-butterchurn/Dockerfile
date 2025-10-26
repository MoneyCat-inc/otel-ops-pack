# Butterchurn Visual Engine - Headless WebGL Milkdrop
# ECRR: BossCat Mission - Containerized visual authoring loop
# Authority: BossCat OEM | Executor: Cursor{Implementer}

# Gate #018: Pinned to digest for supply-chain security
FROM node:20-bullseye@sha256:fd16d0493915f578fe2b2bfb9d9179267076ffc899e47e4bcec9ecd42687c6e7

# Install Chromium and dependencies for headless rendering
# CRITICAL FIX: Add canvas build deps (cairo, pango, jpeg, gif)
RUN apt-get update && apt-get install -y \
    chromium \
    chromium-driver \
    pulseaudio \
    ffmpeg \
    build-essential \
    python3 \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install Node dependencies
RUN npm install

# Copy application code
COPY src/ ./src/
COPY presets/ ./presets/

# Environment defaults
ENV WIDTH=1920
ENV HEIGHT=1080
ENV FPS=60
ENV PRESET_DIR=/app/presets
ENV NODE_ENV=production

# Expose control API port
EXPOSE 7001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node src/health-check.js || exit 1

# Start the visual engine server
CMD ["node", "src/server.js"]

