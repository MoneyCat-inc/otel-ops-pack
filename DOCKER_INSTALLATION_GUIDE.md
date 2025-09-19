# Docker Desktop Installation Guide

## **Current Status**
- ❌ **Docker Desktop**: Not installed
- ❌ **Docker Compose**: Not available
- ❌ **SigNoz Stack**: Cannot start without Docker

## **Installation Steps**

### **Step 1: Download Docker Desktop**
1. Go to: https://www.docker.com/products/docker-desktop
2. Click "Download for Windows"
3. Run the installer: `Docker Desktop Installer.exe`

### **Step 2: Install Docker Desktop**
1. **Run installer as Administrator**
2. **Enable WSL 2** (recommended)
3. **Enable Hyper-V** (if WSL 2 not available)
4. **Restart computer** when prompted

### **Step 3: Start Docker Desktop**
1. **Launch Docker Desktop** from Start menu
2. **Wait for Docker to start** (whale icon in system tray)
3. **Accept license agreement**

### **Step 4: Verify Installation**
```powershell
# Check Docker version
docker --version

# Check Docker Compose
docker-compose --version

# Test Docker
docker run hello-world
```

## **Alternative: Manual SigNoz Installation**

If Docker Desktop installation is not possible, you can run SigNoz components manually:

### **Option 1: SigNoz Cloud**
- Use SigNoz cloud service
- No local installation required
- Update `config.yaml` to point to cloud endpoint

### **Option 2: Local SigNoz Binary**
- Download SigNoz binaries
- Run components manually
- More complex setup

## **Next Steps After Docker Installation**

Once Docker Desktop is installed and running:

```powershell
# Start SigNoz stack
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs
```

## **Troubleshooting**

### **Docker Desktop Won't Start**
- Check Windows version (Windows 10/11 required)
- Enable WSL 2 or Hyper-V
- Run as Administrator
- Check antivirus software

### **WSL 2 Issues**
```powershell
# Update WSL
wsl --update

# Set WSL 2 as default
wsl --set-default-version 2
```

### **Hyper-V Issues**
- Enable Hyper-V in Windows Features
- Restart computer
- Check BIOS virtualization settings

## **System Requirements**

- **Windows 10/11** (64-bit)
- **4GB RAM** minimum (8GB recommended)
- **Virtualization** enabled in BIOS
- **Administrator rights** for installation


