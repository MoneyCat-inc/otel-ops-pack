# 🧪 Test PR Guide - Hardened CI Pipeline

## 🎯 **Quick Test PR to Validate Hardened CI**

### **Step 1: Create a Simple Change**
```bash
# Make a tiny change to trigger CI
echo "# Test: Hardened CI Pipeline Validation" >> README.md
```

### **Step 2: Commit and Push**
```bash
git add README.md
git commit -m "test: validate hardened CI pipeline with all 7 jobs"
git push origin your-branch-name
```

### **Step 3: Create PR**
Create a pull request and watch for these **7 CI jobs**:

## 🔍 **Expected CI Jobs**

### **1. python** 
- ✅ pip cache enabled
- ✅ flake8 linting
- ✅ mypy type checking
- ✅ pytest execution

### **2. node**
- ✅ npm cache enabled  
- ✅ ESLint linting
- ✅ TypeScript type checking
- ✅ Jest testing

### **3. powershell**
- ✅ powershell-yaml installation
- ✅ PSScriptAnalyzer execution

### **4. yamls**
- ✅ yamllint general files
- ✅ yamllint OTel configs (config/*.yaml)

### **5. actionlint**
- ✅ GitHub Actions YAML validation

### **6. otel-config-smoke** ⭐ **Key Job**
- ✅ Pull collector image (0.114.0)
- ✅ Show collector version
- ✅ Create minimal CI config
- ✅ Start collector with OTLP receiver
- ✅ **Send canary span to /v1/traces**
- ✅ Tear down container

### **7. reviewdog-eslint**
- ✅ PR annotations for ESLint issues

## 🎯 **Success Criteria**

All jobs should show ✅ **green** with:
- No YAML validation errors
- No PowerShell script issues  
- No OTel config syntax problems
- **OTLP canary span successfully sent to localhost:4318/v1/traces**

## 🚨 **What to Watch For**

- **Collector version**: Should show `0.114.0` in logs
- **OTLP endpoint**: Should respond to POST on port 4318
- **Canary span**: Should be accepted by collector
- **Cache hits**: Should see "Cache restored from key" for pip/npm

## 📊 **Expected Timeline**

- **Total CI time**: ~3-5 minutes
- **otel-config-smoke**: ~30-60 seconds (includes Docker pull)
- **Other jobs**: ~30 seconds each (with cache hits)

---

**Ready to test? Create that PR and watch the hardened pipeline purr! 🐱‍💻**
