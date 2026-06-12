# ProjectM GPU Engine (Lane PR)

**Track:** B1 (Ubuntu + NVIDIA + VirtualGL)  
**Status:** POST-DEMO IMPLEMENTATION  
**Authority:** BossCat OEM  
**Executor:** Cursor{Implementer}

---

## Purpose

Enable **hardware-accelerated ProjectM rendering** using NVIDIA GPU to reduce CPU usage from **1016% → <100%**.

---

## Architecture

```
┌─────────────────────────────────────────┐
│ Host: Ubuntu 22.04 + NVIDIA Driver     │
│   └─ Headless Xorg :0 (GPU-backed)    │
└─────────────────────────────────────────┘
                ▲
                │ VirtualGL bridge
                │
┌─────────────────────────────────────────┐
│ Container: pm-engine-gpu               │
│   ├─ Xvfb :99 (2D X server)           │
│   ├─ VirtualGL (GLX interceptor)      │
│   └─ ProjectM (GPU-accelerated)       │
└─────────────────────────────────────────┘
                │
                ▼
        MJPEG stream (milk-v0)
```

---

## Key Components

### 1. **Dockerfile.projectm-vgl**
- Based on `nvidia/opengl:1.2-glvnd-runtime-ubuntu22.04`
- Installs VirtualGL, Xvfb, ProjectM
- **No apt-install of nvidia-* drivers** (NVIDIA Container Toolkit injects them)

### 2. **docker/entrypoint.sh**
- Starts Xvfb :99 (2D virtual X server)
- Verifies host GPU X server :0 is accessible
- Launches ProjectM with `vglrun -d :0` (3D → GPU)
- Fallback to Mesa if GPU unavailable

### 3. **docs/gpu/RUN_AND_VERIFY.md**
- Complete setup guide for Ubuntu host
- Host prep: NVIDIA driver + Container Toolkit
- Headless Xorg :0 configuration (VirtualGL)
- Build, run, verify, integrate steps
- Troubleshooting and rollback plan

---

## Quick Start

### Prerequisites
- **Host:** Ubuntu 22.04+ with NVIDIA GPU
- **Docker:** 20.10+ with NVIDIA Container Toolkit
- **GPU X Server:** Headless Xorg :0 running on GPU

### Build & Run

```bash
# Build image
docker build -f Dockerfile.projectm-vgl -t bosscat/viz-engine-projectm-gpu:latest .

# Run with GPU
docker run -d \
  --name pm-engine-gpu \
  --gpus all --runtime nvidia \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=graphics,utility,video \
  -e DISPLAY=:99 -e VGL_DISPLAY=:0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -p 8090:8090 --shm-size 512m \
  bosscat/viz-engine-projectm-gpu:latest

# Verify GPU rendering
docker exec pm-engine-gpu vglrun -d :0 glxinfo -B | grep "OpenGL vendor"
# Expected: OpenGL vendor string: NVIDIA Corporation

# Check CPU usage
docker stats pm-engine-gpu --no-stream
# Expected: CPU < 100% (was 1016%)
```

---

## Evidence Trail

| File | Purpose |
|------|---------|
| `artifacts/ecrr/gpu/PRE_GPU_BASELINE.json` | Current Mesa metrics (1016% CPU) |
| `artifacts/ecrr/gpu/POST_GPU_GLXINFO.txt` | GPU OpenGL verification |
| `artifacts/ecrr/gpu/POST_GPU_STATS.json` | CPU/memory after GPU |
| `docs/BossCat/BOSSCAT_LOG.md` | One-liner lane PR entry |

---

## Expected Outcomes

| Metric | Before (Mesa) | After (GPU) |
|--------|---------------|-------------|
| **OpenGL Vendor** | Mesa | NVIDIA Corporation |
| **CPU Usage** | 1016% | <100% |
| **Stream Quality** | Pausing | Smooth |
| **FPS** | Variable | Stable 30 |

---

## Gate Compliance

**ECRR Methodology:**
1. **Examine:** Baseline captured (`PRE_GPU_BASELINE.json`)
2. **Clean:** New image from `nvidia/opengl` (no apt driver installs)
3. **Report:** Evidence artifacts + `BOSSCAT_LOG.md` entry
4. **Role:** Authority: BossCat OEM | Executor: Cursor{Implementer}

**Budgets:**
- ≤2 jobs (build + verify)
- ≤10 files (4 created: Dockerfile, entrypoint, README, RUN_AND_VERIFY)
- ≤200 LOC (entrypoint: ~150, Dockerfile: ~70)

**Rollback:** If GPU setup fails, revert to `docker-compose.viz.yml` Mesa config.

---

## Why This Works

### Problem: Xvfb + GPU Don't Mix
- Xvfb is a **CPU-only** virtual framebuffer
- No GPU drivers loaded in Xvfb
- ProjectM forced to Mesa software rendering

### Solution: VirtualGL Bridge
- **Xvfb :99** provides 2D X server (app compatibility)
- **VirtualGL** intercepts OpenGL calls
- **Host Xorg :0** renders on GPU
- Results streamed back to Xvfb display

**Reference:** [VirtualGL Headless NVIDIA Guide](https://virtualgl.org/Documentation/HeadlessNV)

---

## References

- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
- [VirtualGL Documentation](https://virtualgl.org/Documentation/HeadlessNV)
- [NVIDIA OpenGL Images](https://hub.docker.com/r/nvidia/opengl)
- [Docker GPU Configurations](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/docker-specialized.html)

---

## Integration with Existing Stack

Replace `pm-engine` service in `docker-compose.viz.yml`:

```yaml
pm-engine:
  build:
    context: ./viz-engine-projectm-gpu
    dockerfile: Dockerfile.projectm-vgl
  image: bosscat/viz-engine-projectm-gpu:latest
  runtime: nvidia
  environment:
    - NVIDIA_VISIBLE_DEVICES=all
    - NVIDIA_DRIVER_CAPABILITIES=graphics,utility,video
    - DISPLAY=:99
    - VGL_DISPLAY=:0
  volumes:
    - /tmp/.X11-unix:/tmp/.X11-unix
  # ... rest of config
```

See `docs/gpu/RUN_AND_VERIFY.md` for complete integration steps.

---

**Status:** Lane PR ready for post-demo implementation  
**Gate Decision:** GREEN (Track A) + APPROVED (Track B)  
**Authority:** BossCat OEM | **Executor:** Cursor{Implementer}






















