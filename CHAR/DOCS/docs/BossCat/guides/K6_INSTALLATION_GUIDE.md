# k6 Installation Guide

## Windows Installation

### Option 1: Chocolatey (Recommended)
```powershell
# Install Chocolatey if not already installed
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install k6
choco install k6
```

### Option 2: Scoop
```powershell
# Install Scoop if not already installed
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

# Install k6
scoop install k6
```

### Option 3: Manual Download
1. Download k6 from https://github.com/grafana/k6/releases
2. Extract the binary to a directory (e.g., `C:\k6\`)
3. Add the directory to your PATH environment variable

## Linux Installation

### Option 1: Package Manager
```bash
# Ubuntu/Debian
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# CentOS/RHEL
sudo yum install https://github.com/grafana/k6/releases/download/v0.47.0/k6-v0.47.0-linux-amd64.rpm
```

### Option 2: Homebrew
```bash
brew install k6
```

## macOS Installation

### Option 1: Homebrew
```bash
brew install k6
```

### Option 2: Manual Download
1. Download k6 from https://github.com/grafana/k6/releases
2. Extract and move to `/usr/local/bin/`

## Verification

After installation, verify k6 is working:
```bash
k6 version
```

## BossCat Integration

Once k6 is installed, the BossCat pipeline will automatically detect and use it. The scripts will:

1. Check for k6 availability
2. Run performance tests (baseline, load, stress, soak)
3. Generate JSON results for gate verification

## Troubleshooting

### k6 Not Found
If you get "k6 not found" errors:
1. Verify k6 is installed: `k6 version`
2. Check PATH environment variable includes k6 directory
3. Restart terminal/command prompt after installation
4. On Windows, ensure you're using PowerShell or Command Prompt (not Git Bash)

### Permission Issues
On Linux/macOS, you may need to make k6 executable:
```bash
chmod +x /path/to/k6
```

### Windows PATH Issues
If k6 is installed but not found:
1. Add k6 directory to PATH in System Environment Variables
2. Restart all terminal windows
3. Verify with `where k6` (Windows) or `which k6` (Linux/macOS)
