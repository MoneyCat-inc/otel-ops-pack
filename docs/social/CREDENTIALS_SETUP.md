# 🔐 SOCM Credentials Setup Guide

**Purpose**: Store Bluesky App Password locally without manual entry  
**Security**: File is gitignored, safe for local use  
**Date**: 2025-10-18

---

## 🎯 Quick Setup (2 minutes)

### **Step 1: Create App Password in Bluesky**

1. **Go to**: https://bsky.app/settings/app-passwords
2. **Click**: "Add App Password"
3. **Name**: `resonai-otel-automation`
4. **Copy** the password (format: `abcd-efgh-ijkl-mnop`)
5. **Save it** (you can't view it again!)

### **Step 2: Create Local Credentials File**

```powershell
# Copy the example file
Copy-Item .env.socm.example .env.socm

# Edit with your real password
notepad .env.socm
```

**Put this in `.env.socm`**:
```
BSKY_HANDLE=resonai.bsky.social
BSKY_APP_PASSWORD=abcd-efgh-ijkl-mnop
BSKY_SERVICE=https://bsky.social
```

**Save and close**.

### **Step 3: Load Credentials** (One command)

```powershell
# Load credentials from file
. ./scripts/social/set-credentials.ps1
```

**Output**:
```
🔐 Loading Bluesky credentials from .env.socm...
  ✓ BSKY_HANDLE
  ✓ BSKY_APP_PASSWORD
  ✓ BSKY_SERVICE

✅ Credentials loaded!
   Handle: resonai.bsky.social

Ready to post:
  npm run social:post
```

### **Step 4: Post** (One command)

```powershell
npm run social:post
```

**Done!** Credentials loaded automatically from `.env.socm` file.

---

## ⚡ **DAILY WORKFLOW** (After Setup)

**Every time you open PowerShell**:

```powershell
# Navigate to repo
cd C:\otel

# Load credentials (dot-source the script)
. ./scripts/social/set-credentials.ps1

# Now you can post all day!
npm run social:compose -- --text "..." --tags "..." --links "..."
npm run social:approve
npm run social:post
```

**Credentials persist** for the entire PowerShell session!

---

## 🔒 Security Features

### **Gitignored**

`.env.socm` is in `.gitignore`:
```
# SOCM Credentials (Bluesky App Passwords)
.env.socm
.env.social
*.env.local
```

✅ **Safe**: Never committed to Git  
✅ **Local-only**: Stays on your machine  
✅ **Revocable**: Can revoke App Password anytime in Bluesky settings

### **App Password vs. Main Password**

**✅ App Password** (Recommended):
- Scoped permissions (posting only)
- Revocable independently
- Safer for automation
- Can create multiple (one per tool)
- Audit trail in Bluesky settings

**❌ Main Password** (Never Use):
- Too privileged (full account access)
- Can't revoke without changing everywhere
- Security risk if leaked
- Not designed for automation

### **If Compromised**

**If `.env.socm` file leaks**:
1. **Go to**: https://bsky.app/settings/app-passwords
2. **Find**: `resonai-otel-automation`
3. **Click**: Revoke
4. **Create**: New App Password
5. **Update**: `.env.socm` with new password

**No need** to change your main Bluesky password!

---

## 🛠️ Alternative: Environment Variables

**If you prefer not to use a file**:

```powershell
# Add to your PowerShell profile (persistent)
notepad $PROFILE

# Add these lines:
$env:BSKY_HANDLE = "resonai.bsky.social"
$env:BSKY_APP_PASSWORD = "your-real-password"
$env:BSKY_SERVICE = "https://bsky.social"

# Save and reload:
. $PROFILE
```

**Then** credentials are always available in PowerShell!

---

## 📋 Troubleshooting

### **"Invalid identifier or password"**

**Cause**: Wrong App Password or using placeholder text

**Fix**:
1. Verify App Password in Bluesky settings
2. Copy the EXACT password (case-sensitive)
3. Update `.env.socm`
4. Reload: `. ./scripts/social/set-credentials.ps1`
5. Retry: `npm run social:post`

### **".env.socm not found"**

**Cause**: File not created yet

**Fix**:
```powershell
Copy-Item .env.socm.example .env.socm
notepad .env.socm  # Add your real password
. ./scripts/social/set-credentials.ps1
```

### **"Credentials not loaded"**

**Cause**: Forgot to dot-source the script

**Fix**:
```powershell
# Wrong (runs in subshell):
./scripts/social/set-credentials.ps1

# Correct (loads into current shell):
. ./scripts/social/set-credentials.ps1
```

**Note the dot** (`. `) before the path!

---

## ✅ Quick Reference

**One-Time Setup**:
```powershell
# 1. Create .env.socm
Copy-Item .env.socm.example .env.socm
notepad .env.socm  # Add your App Password

# 2. Verify it's gitignored
git status  # Should NOT show .env.socm
```

**Daily Usage**:
```powershell
# Load credentials
. ./scripts/social/set-credentials.ps1

# Post
npm run social:post
```

**Check Loaded**:
```powershell
# Verify credentials are set
echo $env:BSKY_HANDLE
# Should show: resonai.bsky.social
```

---

## 🎯 Next Steps

**Now**:
1. Create `.env.socm` from example
2. Add your real App Password
3. Load credentials: `. ./scripts/social/set-credentials.ps1`
4. Post: `npm run social:post`

**Your draft is ready and approved** - just needs valid credentials! 🚀

---

**Files Created**:
- `.env.socm.example` - Template (committed)
- `scripts/social/set-credentials.ps1` - Loader script (committed)
- `.env.socm` - Your file (gitignored, you create this)

🐾 **No more manual password entry - just dot-source once per session!**

