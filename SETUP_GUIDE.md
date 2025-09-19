# Observability Stack Setup Guide

## **Current Status**
- ❌ **Docker Desktop**: Not installed/running
- ❌ **SigNoz Stack**: Not running (no containers)
- ❌ **Windows Collector**: Not installed/running
- ✅ **Configuration**: Ready (`config.yaml`, `docker-compose.yml`)

## **Setup Options**

### **Option 1: Automated Setup (Recommended)**

Run the complete startup script:

```powershell
# Full automated setup
.\startup-observability.ps1

# Or skip Docker if already running
.\startup-observability.ps1 -SkipDocker

# Or skip Windows Collector installation
.\startup-observability.ps1 -SkipCollector
```

### **Option 2: Manual Setup**

#### **Step 1: Install Docker Desktop**
1. Download from: https://www.docker.com/products/docker-desktop
2. Install and start Docker Desktop
3. Wait for Docker to be ready

#### **Step 2: Start SigNoz Stack**
```powershell
# Start SigNoz containers
docker-compose up -d

# Check status
docker-compose ps
```

#### **Step 3: Install Windows Collector**
1. Open PowerShell as Administrator
2. Run: `.\startup-observability.ps1 -SkipDocker`

#### **Step 4: Verify Integration**
```powershell
.\verify-integration.ps1
```

## **What Gets Started**

### **SigNoz Stack** (Docker)
- **SigNoz UI**: http://localhost:8080
- **OTEL Collector**: Ports 14317/14318 (gRPC/HTTP)
- **ClickHouse**: Database for storage
- **Metrics**: Port 8888

### **Windows Collector** (Service)
- **OTLP Receivers**: Ports 5317/5318 (gRPC/HTTP)
- **Health Check**: Port 13134
- **Metrics**: Port 8888 (if not conflicting)

## **Expected Results**

After successful setup:
- ✅ All ports listening (5317/5318, 14317/14318, 8080, 8888, 13134)
- ✅ SigNoz UI accessible at http://localhost:8080
- ✅ Windows collector service running
- ✅ Verification script shows all [OK]

## **Troubleshooting**

### **Docker Issues**
```powershell
# Check Docker status
docker --version
docker ps

# Check Docker Desktop
Get-Process | Where-Object {$_.ProcessName -like "*docker*"}
```

### **Windows Collector Issues**
```powershell
# Check service
Get-Service otelcol-contrib

# Check ports
netstat -an | findstr "5317\|5318"

# Check logs
Get-EventLog -LogName Application -Source otelcol-contrib -Newest 5
```

### **SigNoz Issues**
```powershell
# Check containers
docker-compose ps

# Check logs
docker-compose logs signoz
docker-compose logs signoz-otel-collector
```

## **Verification**

Once everything is running:

```powershell
# Run comprehensive verification
.\verify-integration.ps1

# Check SigNoz UI
start http://localhost:8080

# Look for canary logs
# In SigNoz: Logs → Filter: log.body contains "windows-canary-"
```

## **Files Created**

- `docker-compose.yml` - SigNoz stack configuration
- `startup-observability.ps1` - Automated setup script
- `verify-integration.ps1` - Verification script (improved)
- `config.yaml` - Windows collector configuration

## **Next Steps**

1. **Choose setup option** (automated or manual)
2. **Run setup script** or follow manual steps
3. **Verify integration** with verification script
4. **Check SigNoz UI** for canary logs
5. **Monitor system** with your improved scripts


