# 🚀 BossCat CI/CD Deployment Guide

## Step 1: Deploy GitHub Actions Workflow

Copy the workflow file to the correct location:

```bash
# From your repository root
cp scripts/bosscat-gate-verify-workflow.yml .github/workflows/bosscat-gate-verify.yml
```

## Step 2: Configure Repository Secrets (Optional)

If you want to use a real SigNoz instance in CI, add these secrets in your GitHub repository settings:

- `SIGNOZ_URL`: Your SigNoz instance URL
- `SIGNOZ_API_KEY`: Your SigNoz API key
- `OTLP_ENDPOINT`: OTLP endpoint (e.g., `https://your-signoz.com:4317`)

## Step 3: Trigger the Workflow

The workflow will automatically run on:
- **Push to main/develop branches**
- **Pull requests to main**
- **Manual dispatch** (with custom parameters)

## Step 4: Monitor Results

After deployment, you'll see:
- ✅ **Automated testing** on every commit
- 📊 **Performance metrics** and thresholds
- 📋 **ECRR and BOSS v2 reports** generated automatically
- 🎯 **Build failures** if performance thresholds are breached

## Step 5: Customize for Your Environment

### Adjust Test Thresholds
Edit the k6 scripts in `tests/k6/` to match your performance requirements:

```javascript
thresholds: {
  http_req_duration: ["p(95)<200"],  // Adjust based on your SLA
  http_req_failed: ["rate<0.01"],    // Adjust error tolerance
  checks: ["rate==0"]                // Adjust check success rate
}
```

### Configure Test Types
Modify the workflow to run different test combinations:

```yaml
# In the workflow file
python scripts/run-local-pipeline.py \
  --test-types="baseline,load" \  # Add stress,soak as needed
  --verbose
```

## 🎯 Expected CI Results

Once deployed, you'll see:

### ✅ Successful Run
```
✓ Run linting
✓ Run unit tests  
✓ Run dry-run test
✓ Run BossCat pipeline
✓ Upload artifacts
✓ Generate ECRR Report
✓ Generate BOSS v2 Report
✓ Commit reports
```

### 📊 Generated Artifacts
- `bosscat-test-results/` - Test results and logs
- `ECRR_CI_RUN.md` - Emergency Change Review Report
- `BOSS_v2_CI_RUN.md` - Business Operations System Summary
- PDF versions of both reports

### 🚨 Threshold Breaches
If performance thresholds are exceeded:
- ❌ Build fails with clear error messages
- 📋 Detailed metrics in artifacts
- 🔍 Specific threshold violations highlighted

## 🔧 Troubleshooting CI Issues

### Common Problems
1. **k6 Installation**: Already handled in workflow
2. **Locust Installation**: Already handled in workflow  
3. **Python Dependencies**: Already handled in workflow
4. **Mock API**: Automatically started for CI runs

### Debug Commands
```bash
# Check workflow logs in GitHub Actions
# Look for specific step failures
# Download artifacts to inspect detailed results
```

## 🎉 Success Criteria

Your CI pipeline is working when you see:
- ✅ Green checkmarks on all commits
- 📊 Performance metrics within thresholds
- 📋 Reports generated and committed automatically
- 🚨 Red X on commits that breach performance thresholds

---

**Ready to deploy? Just copy the workflow file and push to your repository!** 🚀
