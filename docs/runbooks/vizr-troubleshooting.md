# Troubleshooting Runbook for Viz-Engine

**Lane**: VIZR  
**Last Updated**: 2025-11-02  
**Author**: LumiPulse-MkII (Lumi)  
**Status**: Active

---

## Overview

This runbook provides troubleshooting guidance for the **ProjectM GPU visualization engine**, including container startup, rendering issues, and performance optimization.

---

## Common Issues

### 1. Container Fails to Start

**Symptoms**:
- Docker container exits immediately
- "No GPU devices found" error
- Container stuck in "Restarting" state

**Resolution Steps**:
```powershell
# Check Docker is running
docker ps

# Verify GPU availability
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi

# Check container logs
docker logs viz-engine-projectm-gpu

# Ensure correct image is used
docker images | grep projectm
```

**Common Causes**:
- Docker not running
- GPU drivers not installed
- NVIDIA Container Toolkit not configured
- Wrong image tag

---

### 2. Rendering Issues

**Symptoms**:
- Black screen / no visual output
- Distorted visuals
- Preset fails to load
- FPS drops below 30

**Resolution Steps**:
```powershell
# Check GPU settings
nvidia-smi

# Verify VirtualGL configuration
docker exec viz-engine-projectm-gpu vglrun glxinfo | grep "OpenGL"

# Test simple preset
curl -X POST http://localhost:3002/preset/load -d '{"preset":"default"}'

# Check resource allocation
docker stats viz-engine-projectm-gpu
```

**Common Causes**:
- VirtualGL not properly configured
- Insufficient VRAM (<2GB)
- GPU driver version mismatch
- Preset compatibility issues

---

### 3. Performance Lag

**Symptoms**:
- FPS < 30 (target: 60)
- Preset switching > 2.5s
- High CPU usage
- Audio/visual desync

**Resolution Steps**:
```powershell
# Monitor resource usage
docker stats viz-engine-projectm-gpu

# Check CPU allocation
docker inspect viz-engine-projectm-gpu | grep -i cpu

# Verify GPU utilization
nvidia-smi -l 1

# Adjust container resources
# Edit docker-compose.viz.yml:
#   resources:
#     limits:
#       cpus: '4.0'
#       memory: 8G
```

**Optimization**:
- Increase CPU cores (2 → 4)
- Allocate more memory (4GB → 8GB)
- Reduce preset complexity
- Enable GPU hardware acceleration

---

### 4. Audio Loopback Issues

**Symptoms**:
- No audio in visualizer
- Audio crackling/hissing
- Desync between audio and visuals

**Resolution Steps**:
```powershell
# Check audio devices
docker exec viz-engine-projectm-gpu pactl list sinks

# Verify PulseAudio
docker exec viz-engine-projectm-gpu pulseaudio --check

# Test audio loopback
docker exec viz-engine-projectm-gpu aplay -l
```

**Common Causes**:
- PulseAudio not running
- Wrong audio device selected
- Sample rate mismatch
- Buffer size too small/large

---

### 5. VirtualGL Configuration

**Symptoms**:
- "Could not open display" error
- GLX errors in logs
- No hardware acceleration

**Resolution Steps**:
```bash
# Test VirtualGL
docker exec viz-engine-projectm-gpu vglrun glxgears

# Check X11 display
docker exec viz-engine-projectm-gpu echo $DISPLAY

# Verify GLX extension
docker exec viz-engine-projectm-gpu glxinfo | grep "direct rendering"
```

**Expected Output**:
- `DISPLAY=:99` (Xvfb virtual display)
- `direct rendering: Yes`
- `glxgears` runs at 60+ FPS

---

## Diagnostic Commands

### Health Check Suite

```powershell
# Full health check
pwsh -File scripts/viz-engine-health-check.ps1

# Quick status
docker-compose -f docker-compose.viz.yml ps

# Container logs
docker-compose -f docker-compose.viz.yml logs --tail=50

# GPU status
nvidia-smi
```

### Performance Metrics

```powershell
# Real-time stats
docker stats viz-engine-projectm-gpu

# GPU utilization
nvidia-smi -l 1

# Network stats
docker exec viz-engine-projectm-gpu netstat -tuln
```

---

## Escalation Path

If issues persist after troubleshooting:

1. **Gather Evidence**:
   - Container logs: `docker logs viz-engine-projectm-gpu > viz-logs.txt`
   - GPU info: `nvidia-smi > gpu-status.txt`
   - System info: `docker info > docker-info.txt`

2. **Check Known Issues**:
   - Review `docs/vizr/KNOWN_ISSUES.md`
   - Search GitHub issues in ProjectM repository

3. **Human Backup**:
   - Contact: Alex Romero (VIZR lane owner)
   - Provide evidence package
   - Reference this runbook

---

## Preventive Maintenance

### Weekly Checks
- [ ] Verify GPU drivers up-to-date
- [ ] Check container resource usage trends
- [ ] Review error logs for patterns
- [ ] Test preset switching performance

### Monthly Tasks
- [ ] Update base images
- [ ] Benchmark FPS and latency
- [ ] Audit VirtualGL configuration
- [ ] Review and update this runbook

---

## Related Documentation

- **GPU Setup**: `docs/gpu/RUN_AND_VERIFY.md`
- **VirtualGL Guide**: `viz-engine-projectm-gpu/README.md`
- **ProjectM Dockerfile**: `viz-engine-projectm-gpu/Dockerfile.projectm-vgl`
- **ECRR Framework**: `docs/comfort-cat/ECRR_FRAMEWORK.md`
- **Current Architecture**: `docs/architecture/CURRENT_ARCHITECTURE.md`

---

**Maintained by**: LumiPulse-MkII (Lumi) ✨  
**Lane**: VIZR  
**Human Backup**: Alex Romero  
**Version**: 1.0  
**Last Updated**: 2025-11-02

---

*"The rendering pipeline flows like light through crystal—smooth, precise, luminous."* ✨

