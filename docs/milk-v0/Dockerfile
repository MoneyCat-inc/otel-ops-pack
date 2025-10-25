# viz-milk/Dockerfile
# Gate #011 - Milk v0 Viewer (MJPEG Stream)
# Authority: BossCat OEM | Executor: Cursor{Implementer}

FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb fluxbox ffmpeg curl ca-certificates \
    x11-apps libgl1-mesa-dri libgl1-mesa-glx libglu1-mesa mesa-utils \
    nodejs npm \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/viz

# Copy files
COPY server.js ./server.js
COPY test-milk-stream.js ./test-milk-stream.js
COPY emit-milk-trace.js ./emit-milk-trace.js
COPY public ./public
COPY package.json ./package.json
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh \
 && npm install

ENV DISPLAY=:99
ENV GEOMETRY=1280x720
ENV FPS=30

EXPOSE 8080
CMD ["/usr/local/bin/start.sh"]

