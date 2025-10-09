# Runbook: Service CI/CD Setup

**Version:** 1.0  
**Last Updated:** 2025-10-09  
**Audience:** DevOps, Developers

---

## 🎯 Overview

This runbook explains how to set up CI/CD for a new service/application using the tetragram-compliant workflow template.

**Principles:**
- ✅ Workflows stay thin (delegate to BRAV/SCPT/)
- ✅ Inline run blocks ≤ 20 lines
- ✅ All logic testable locally
- ✅ Guardrails enforced on every build

---

## 📦 Prerequisites

### 1. Application Exists
Your app should be under `ALFA/APPS/<APP_NAME>/` with:
- `package.json` (with `build`, `test` scripts)
- `src/` directory
- `Dockerfile` (for containerization)

**Create new app:**
```bash
bash BRAV/SCPT/new_app.sh my-service
```

### 2. Repository Secrets Configured

**GitHub Repository Secrets** (Settings → Secrets and variables → Actions):
- `NPM_TOKEN` (optional) - NPM registry auth
- `REGISTRY_TOKEN` - Docker registry auth token
- `REGISTRY_USER` - Docker registry username

### 3. Repository Variables Configured

**GitHub Repository Variables**:
- `REGISTRY_HOST` - Docker registry (e.g., `ghcr.io`, `docker.io`)
- `IMAGE_PREFIX` (optional) - Image name prefix (e.g., `resonai`)
- `ROLL_OUT_DEV` (optional) - Set to `true` to auto-deploy DEV

---

## 🚀 Setup Steps

### Step 1: Copy Template Workflow

```bash
# Copy the template
cp .github/workflows/app-template.yml .github/workflows/app-my-service.yml

# Replace <APP_NAME> with your actual app name
sed -i 's/<APP_NAME>/my-service/g' .github/workflows/app-my-service.yml
```

**Or manually:**
1. Copy `.github/workflows/app-template.yml`
2. Rename to `app-<YOUR_APP>.yml`
3. Find/replace all `<APP_NAME>` with your app folder name

### Step 2: Verify BRAV/SCPT Scripts

Ensure these scripts exist (they're part of the template):
- ✅ `BRAV/SCPT/build.sh` - Build script
- ✅ `BRAV/SCPT/test.sh` - Test script
- ✅ `BRAV/SCPT/deploy.sh` - Deploy script
- ✅ `BRAV/SCPT/rollout_kustomize.sh` (optional) - Kustomize rollout

All scripts are executable and tested.

### Step 3: Test Locally

Before committing, test the scripts locally:

```bash
# Build
bash BRAV/SCPT/build.sh ALFA/APPS/my-service

# Test
bash BRAV/SCPT/test.sh ALFA/APPS/my-service

# Deploy (dry-run)
REGISTRY=ghcr.io IMAGE_NAME=my-service IMAGE_TAG=test \
  bash BRAV/SCPT/deploy.sh ALFA/APPS/my-service package
```

### Step 4: Commit and Push

```bash
git add .github/workflows/app-my-service.yml
git commit -m "ci(app): add CI/CD workflow for my-service

- Guardrails check (required)
- Build and test (delegated to BRAV/SCPT/)
- Containerize and deploy (main branch only)
- Thin workflow (<20 lines per step)
- Tetragram compliant"

git push origin main
```

### Step 5: Verify in GitHub Actions

1. Open a PR that touches `ALFA/APPS/my-service/`
2. Check that workflow runs
3. Verify guardrails pass
4. Verify build and test succeed
5. Merge to main
6. Verify containerize and deploy run (if configured)

---

## 📋 Workflow Structure

### Jobs

**1. guardrails** (runs on all PRs + pushes)
- Checks repository structure
- Strict mode on main, regular on branches
- Must pass before build/test

**2. build_test** (runs after guardrails)
- Sets up Node.js environment
- Calls `BRAV/SCPT/build.sh`
- Calls `BRAV/SCPT/test.sh`
- Uploads test results as artifacts

**3. containerize_and_deploy** (main branch only)
- Builds Docker image
- Pushes to registry
- Optional: Rolls out to DEV environment

---

## 🔧 Script Details

### build.sh

**Purpose:** Build the application

**Usage:**
```bash
bash BRAV/SCPT/build.sh ALFA/APPS/<APP_NAME>
```

**What it does:**
1. Changes to app directory
2. Runs `npm ci` (clean install)
3. Runs `npm run build` (if defined)
4. Disables Next.js telemetry

**Customization:**
Edit `BRAV/SCPT/build.sh` to add app-specific build steps.

---

### test.sh

**Purpose:** Run tests for the application

**Usage:**
```bash
bash BRAV/SCPT/test.sh ALFA/APPS/<APP_NAME>
```

**What it does:**
1. Changes to app directory
2. Runs `npm test` with CI reporters
3. Outputs results to `out/test-results/<APP_NAME>/`
4. Tries junit, json, or standard reporters

**Customization:**
Edit `BRAV/SCPT/test.sh` to change test configuration or reporters.

---

### deploy.sh

**Purpose:** Package, push, and deploy application

**Usage:**
```bash
# Package (build Docker image)
bash BRAV/SCPT/deploy.sh ALFA/APPS/<APP_NAME> package

# Push (to registry)
bash BRAV/SCPT/deploy.sh ALFA/APPS/<APP_NAME> push

# Rollout (to environment)
bash BRAV/SCPT/deploy.sh ALFA/APPS/<APP_NAME> rollout DEV
```

**Environment Variables:**
- `REGISTRY` - Docker registry host (default: ghcr.io)
- `IMAGE_NAME` - Image name (default: app)
- `IMAGE_TAG` - Image tag (default: dev)

**What it does:**
- **package:** Builds Docker image from Dockerfile
- **push:** Pushes image to registry
- **rollout:** Deploys to environment (calls rollout helper)

**Customization:**
- Add Dockerfile to `ALFA/APPS/<APP_NAME>/Dockerfile`
- Or create `BRAV/DOCK/Dockerfile.<APP_NAME>`
- Implement rollout logic in `BRAV/SCPT/rollout_*.sh`

---

### rollout_kustomize.sh (Optional)

**Purpose:** Deploy using Kustomize overlays

**Usage:**
```bash
bash BRAV/SCPT/rollout_kustomize.sh DEV ghcr.io/org/app:abc123
```

**Prerequisites:**
- Kustomize overlays in `DELT/CONF/OVER/<ENV>/`
- kubectl configured for target cluster
- `kustomize` CLI installed (optional for validation)

**What it does:**
1. Validates overlay exists
2. Validates kustomization.yaml (if kustomize installed)
3. Patches image in overlay
4. Applies to cluster (if `APPLY_DEPLOY=true`)

**Customization:**
- Adjust overlay paths to your structure
- Add environment-specific logic
- Integrate with helm if preferred

---

## 🔍 Testing CI Locally

### Test Build Script
```bash
cd c:\otel  # or your repo root

# Test build
bash BRAV/SCPT/build.sh ALFA/APPS/app

# Check for errors
echo $?  # Should be 0
```

### Test Test Script
```bash
# Test tests (meta!)
bash BRAV/SCPT/test.sh ALFA/APPS/app

# Check results
ls out/test-results/app/
```

### Test Deploy Script
```bash
# Test package (dry-run)
REGISTRY=localhost IMAGE_NAME=test IMAGE_TAG=dev \
  bash BRAV/SCPT/deploy.sh ALFA/APPS/app package

# Verify image was built
docker images | grep test
```

---

## 🛡️ Guardrails Compliance

### Workflow Compliance Check

**This template complies with guardrails:**
- ✅ Each step calls ONE BRAV/SCPT/ script
- ✅ Inline logic ≤ 10 lines per step (well under 20 limit)
- ✅ Workflows reference BRAV/SCPT/ (satisfies required check)
- ✅ No long inline run blocks

**Verify:**
```bash
python BRAV/SCPT/check_guardrails.py --config BRAV/SCPT/guardrails.json
```

Should show no warnings about your new workflow file.

---

## 📊 Multi-App Setup

### For Multiple Apps

**Option 1: Individual Workflows**
- Create `app-service-1.yml`, `app-service-2.yml`, etc.
- Each targets specific app path
- Clear, focused, easy to understand

**Option 2: Matrix Workflow**
```yaml
jobs:
  build_test:
    strategy:
      matrix:
        app: [service-1, service-2, service-3]
    steps:
      - name: Build
        run: bash BRAV/SCPT/build.sh ALFA/APPS/${{ matrix.app }}
      - name: Test
        run: bash BRAV/SCPT/test.sh ALFA/APPS/${{ matrix.app }}
```

**Recommendation:** Use individual workflows for critical apps, matrix for similar microservices.

---

## 🔐 Security Best Practices

### Secrets Management
- ✅ Never commit secrets to workflows
- ✅ Use GitHub Secrets for sensitive data
- ✅ Use GitHub Variables for non-sensitive config
- ✅ Rotate tokens regularly

### Image Security
- ✅ Scan images before push (add security scan step)
- ✅ Use minimal base images
- ✅ Pin dependency versions
- ✅ Sign images (optional)

### Deployment Safety
- ✅ Dry-run by default (`APPLY_DEPLOY=false`)
- ✅ Require manual approval for PROD
- ✅ Use separate workflows for different environments
- ✅ Test in DEV/STAG before PROD

---

## 🧪 Example: Complete Setup

### 1. Create New Service
```bash
# Scaffold
bash BRAV/SCPT/new_app.sh monitoring-dashboard

# Implement
cd ALFA/APPS/monitoring-dashboard
npm install express
# ... add code
```

### 2. Add Dockerfile
```dockerfile
# ALFA/APPS/monitoring-dashboard/Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
CMD ["npm", "start"]
```

### 3. Create CI Workflow
```bash
# Copy template
cp .github/workflows/app-template.yml \
   .github/workflows/app-monitoring-dashboard.yml

# Replace placeholders
sed -i 's/<APP_NAME>/monitoring-dashboard/g' \
   .github/workflows/app-monitoring-dashboard.yml
```

### 4. Test Locally
```bash
# Build
bash BRAV/SCPT/build.sh ALFA/APPS/monitoring-dashboard

# Test
bash BRAV/SCPT/test.sh ALFA/APPS/monitoring-dashboard

# Package
REGISTRY=localhost IMAGE_NAME=monitoring-dashboard IMAGE_TAG=dev \
  bash BRAV/SCPT/deploy.sh ALFA/APPS/monitoring-dashboard package
```

### 5. Commit and Verify
```bash
git add ALFA/APPS/monitoring-dashboard \
        .github/workflows/app-monitoring-dashboard.yml
git commit -m "feat(app): add monitoring-dashboard with CI/CD"
git push origin feat/monitoring-dashboard

# Open PR, verify CI runs
```

---

## 🚨 Troubleshooting

### Build Fails: "npm: command not found"
**Fix:** Ensure `setup-node` step runs before build step

### Test Fails: "No test script"
**Fix:** Add `"test": "..."` to package.json or remove test step from workflow

### Deploy Fails: "No Dockerfile"
**Fix:** Add Dockerfile to `ALFA/APPS/<APP_NAME>/Dockerfile` or `BRAV/DOCK/`

### Guardrails Fail: "Workflow has long inline run"
**Fix:** Extract logic to BRAV/SCPT/ script, call from workflow

### Image Push Fails: "authentication required"
**Fix:** Configure REGISTRY_TOKEN and REGISTRY_USER secrets

---

## 📚 Related Documentation

- **Component Guide:** `CHAR/DOCS/runbooks/tetragram-new-component.md`
- **CI Delegation:** `CHAR/DOCS/runbooks/ci-delegation.md`
- **Day-2 Operations:** `DAY2_OPERATIONS_GUIDE.md`
- **Template Workflow:** `.github/workflows/app-template.yml`

---

## 🐾 BossCat Compliance

**This template is:**
- ✅ Tetragram-compliant (all paths correct)
- ✅ Guardrails-friendly (thin workflows, BRAV/SCPT delegation)
- ✅ Testable locally (all scripts can run outside CI)
- ✅ Maintainable (logic in version-controlled scripts)
- ✅ Extensible (easy to add steps/environments)

**Violations prevented:**
- ❌ No long inline run blocks
- ❌ No hardcoded secrets
- ❌ No committed ephemerals (out/, dist/, etc.)
- ❌ No legacy path references

---

**Version:** 1.0  
**Maintained by:** BossCat OEM  
**Template:** `.github/workflows/app-template.yml`  
**Last Verified:** 2025-10-09

