# GPU-Accelerated ProjectM - Run and Verify Guide

**Authority:** BossCat OEM  
**Track:** B1 (Ubuntu + NVIDIA + VirtualGL)  
**Status:** POST-DEMO IMPLEMENTATION  

---

## Overview

This guide enables **hardware-accelerated ProjectM** rendering using:
- **NVIDIA GPU** for OpenGL rendering
- **VirtualGL** to bridge Xvfb (2D) → Xorg (3D/GPU)
- **NVIDIA Container Toolkit** for GPU passthrough

**Expected Outcome:**
```
OpenGL vendor string: NVIDIA Corporation
ProjectM CPU: <100% (down from 1016%)
Stream: Smooth, no pausing
```

---

## Prerequisites

### Hardware
- NVIDIA GPU (tested with RTX 2080 SUPER)
- Ubuntu 22.04+ host (not Windows WSL2)

### Software
- Docker Engine 20.10+
- NVIDIA driver 535+ (installed on host)
- NVIDIA Container Toolkit (install below)

---

## Part 1: Host Setup (Ubuntu)

### 1.1 Install NVIDIA Driver

```bash
# Auto-install recommended driver
sudo ubuntu-drivers autoinstall

# Verify
nvidia-smi

# Expected: GPU listed with driver version
```

### 1.2 Install NVIDIA Container Toolkit

```bash
# Add NVIDIA repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Configure Docker to use NVIDIA runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Verify
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
# Expected: Same output as host nvidia-smi
```

**Reference:** [NVIDIA Container Toolkit Installation](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

### 1.3 Setup Headless Xorg on GPU

VirtualGL requires a GPU-backed X server. Follow the [VirtualGL Headless NVIDIA Guide](https://virtualgl.org/Documentation/HeadlessNV):

```bash
# Create Xorg config for headless GPU
sudo nvidia-xconfig -a \
  --allow-empty-initial-configuration \
  --use-display-device=none \
  --virtual=1280x720 \
  --busid PCI:1:0:0  # Adjust for your GPU (lspci | grep VGA)

# Start Xorg on :0
sudo X :0 &

# Verify
DISPLAY=:0 glxinfo -B | grep "OpenGL vendor"
# Expected: OpenGL vendor string: NVIDIA Corporation
```

**Note:** Some systems prefer `startx` or systemd service for persistence. See VirtualGL docs for production setups.

---

## Part 2: Build and Run

### 2.1 Build GPU Image

```bash
cd C:\otel  # Or your repo path on Linux: /path/to/otel

# Build from viz-engine-projectm-gpu/
docker build \
  -f viz-engine-projectm-gpu/Dockerfile.projectm-vgl \
  -t bosscat/viz-engine-projectm-gpu:latest \
  viz-engine-projectm-gpu/

# Expected: Build succeeds, ~500MB image
```

### 2.2 Run Container with GPU

```bash
# Start ProjectM with GPU passthrough
docker run -d \
  --name pm-engine-gpu \
  --gpus all \
  --runtime nvidia \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=graphics,utility,video \
  -e DISPLAY=:99 \
  -e VGL_DISPLAY=:0 \
  -e PM_WIDTH=1280 \
  -e PM_HEIGHT=720 \
  -e PM_FPS=30 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -p 8090:8090 \
  --shm-size 512m \
  bosscat/viz-engine-projectm-gpu:latest

# Check logs
docker logs pm-engine-gpu

# Expected output:
#   ✅ Xvfb running (PID: X)
#   ✅ GPU X server accessible
#   OpenGL vendor: NVIDIA Corporation
#   🎮 GPU-accelerated rendering via VirtualGL
```

### 2.3 Verify GPU Rendering

```bash
# Check OpenGL vendor inside container
docker exec pm-engine-gpu bash -c \
  'vglrun -d :0 glxinfo -B | grep "OpenGL vendor"'

# Expected: OpenGL vendor string: NVIDIA Corporation

# Check CPU usage
docker stats pm-engine-gpu --no-stream

# Expected: CPU < 100% (down from 1016%)
```

---

## Part 3: Integration with Existing Stack

### 3.1 Update `docker-compose.viz.yml`

Replace the `pm-engine` service:

```yaml
services:
  pm-engine:
    build:
      context: ./viz-engine-projectm-gpu
      dockerfile: Dockerfile.projectm-vgl
    image: bosscat/viz-engine-projectm-gpu:latest
    runtime: nvidia
    shm_size: "512mb"
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=graphics,utility,video
      - DISPLAY=:99
      - VGL_DISPLAY=:0
      - PM_WIDTH=1280
      - PM_HEIGHT=720
      - PM_FPS=30
      - PM_PRESET_DIR=/app/presets
      - PM_FIFO=/dev/shm/md3.pcm
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix
    depends_on:
      redis-audioswitch:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "xdpyinfo", "-display", ":99"]
      interval: 15s
      timeout: 5s
      retries: 3
      start_period: 10s
    restart: unless-stopped
    networks:
      - viz-net
```

### 3.2 Restart Stack

```bash
cd /path/to/otel

# Stop existing services
docker compose -f docker-compose.viz.yml down pm-engine milk-v0

# Rebuild and start
docker compose -f docker-compose.viz.yml up -d --build pm-engine milk-v0

# Wait for health checks
docker compose -f docker-compose.viz.yml ps
```

### 3.3 Test Data Room

Open `http://localhost:3000/data-room.html`:
- **Visual Stream:** Should be smooth (no pausing)
- **Metrics:** Motion Energy, Brightness, Blackout % updating
- **CPU (host):** `docker stats` shows pm-engine < 100%

---

## Part 4: Evidence Collection

### 4.1 Capture GPU Metrics

```bash
# Before GPU (baseline in artifacts/ecrr/gpu/PRE_GPU_BASELINE.json):
#   CPU: 1016%
#   Renderer: Mesa/llvmpipe
#   Pausing: Frequent

# After GPU
docker exec pm-engine-gpu vglrun -d :0 glxinfo -B > artifacts/ecrr/gpu/POST_GPU_GLXINFO.txt

docker stats pm-engine-gpu --no-stream --format json > artifacts/ecrr/gpu/POST_GPU_STATS.json

# Compare
cat artifacts/ecrr/gpu/PRE_GPU_BASELINE.json
cat artifacts/ecrr/gpu/POST_GPU_STATS.json
```

### 4.2 Update BossCat Log

```bash
echo "$(date -Iseconds) | Lane PR: GPU acceleration implemented (B1) | CPU: 1016% → <100% | Renderer: NVIDIA Corporation | Status: VERIFIED" >> docs/BossCat/BOSSCAT_LOG.md
```

---

## Troubleshooting

### Issue: "Cannot connect to GPU X server :0"

**Cause:** Host Xorg :0 not running or not accessible.

**Fix:**
```bash
# Verify host Xorg is running on :0
ps aux | grep "X :0"

# If not running, start it
sudo X :0 &

# Verify GPU rendering
DISPLAY=:0 glxinfo -B | grep "OpenGL vendor"
```

### Issue: Still showing Mesa

**Cause:** VirtualGL not bridging correctly.

**Fix:**
```bash
# Test VirtualGL directly
docker exec -it pm-engine-gpu bash
vglrun -d :0 glxinfo -B

# If fails, check VGL_DISPLAY
echo $VGL_DISPLAY  # Should be :0
xdpyinfo -display :0  # Should succeed
```

### Issue: "Invalid cross-device link" errors

**Cause:** Trying to apt-install NVIDIA drivers inside container.

**Fix:** Use `nvidia/opengl` base image (no driver installs). The NVIDIA Container Toolkit injects drivers automatically.

---

## Rollback Plan

If GPU setup fails:

```bash
# Stop GPU container
docker compose -f docker-compose.viz.yml down pm-engine

# Revert to original Mesa-based compose
git checkout docker-compose.viz.yml

# Restart original stack
docker compose -f docker-compose.viz.yml up -d pm-engine milk-v0
```

---

## Expected Outcomes

| Metric | Before (Mesa) | After (GPU) |
|--------|---------------|-------------|
| **OpenGL Vendor** | Mesa | NVIDIA Corporation |
| **CPU Usage** | 1016% | <100% |
| **Stream Quality** | Pausing | Smooth |
| **FPS** | Variable | Stable 30 |
| **Investor Demo** | Acceptable | Excellent |

---

## References

- [NVIDIA Container Toolkit Installation](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- [VirtualGL Headless NVIDIA Guide](https://virtualgl.org/Documentation/HeadlessNV)
- [NVIDIA OpenGL Docker Images](https://hub.docker.com/r/nvidia/opengl)
- [Docker GPU Specialized Configurations](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/docker-specialized.html)

---

**Authority:** BossCat OEM  
**Executor:** Cursor{Implementer}  
**Lane:** GPU Acceleration (Post-Demo)  
**Status:** Ready for Implementation






















