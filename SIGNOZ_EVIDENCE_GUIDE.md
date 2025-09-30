# SigNoz Evidence Collection Guide

## Optional Evidence: SigNoz Log View Snapshot

### Step-by-Step Instructions

1. **Open SigNoz UI**
   - Navigate to: `http://localhost:8080`
   - Wait for UI to load completely

2. **Access Logs Section**
   - Click on **"Logs"** in the left sidebar
   - Ensure you're in the main logs view

3. **Apply Canary Filter**
   **Option A - Windows Event Canary:**
   - Click **"Add Filter"** or use the filter bar
   - Filter: `message contains "SigNoz test error"`
   - Press Enter or click Apply

   **Option B - File Log Canary:**
   - Click **"Add Filter"** or use the filter bar  
   - Filter: `log.file.path contains "C:/logs/app.json"`
   - Press Enter or click Apply

4. **Verify Results**
   - Should see recent log entries (last few minutes)
   - Look for entries with timestamps around current time
   - Expected format: JSON logs with canary test data

5. **Take Screenshot**
   - Capture the filtered log view
   - Include the filter applied in the screenshot
   - Note the timestamp of most recent entries

### Expected Results

**Windows Event Canary Filter:**
```
message contains "SigNoz test error"
```
- Should show recent Windows Event Log entries
- Timestamps should be recent (within last 5 minutes)
- Event IDs around 1001

**File Log Canary Filter:**
```
log.file.path contains "C:/logs/app.json"
```
- Should show file-based log entries
- JSON format with canary test data
- Recent timestamps

### Troubleshooting

**If No Results Appear:**
1. Wait 30-60 seconds after running canary test
2. Try refreshing the SigNoz UI
3. Check if filter syntax is correct (no extra spaces)
4. Verify canary test actually ran successfully

**Alternative Verification:**
- Use the `verify-pipeline.ps1` script for programmatic verification
- Check `C:\logs\` directory for canary log files
- Use Windows Event Viewer to see Application logs

### Evidence Value

This screenshot serves as:
- **Visual confirmation** of observability pipeline health
- **Documentation** of successful log ingestion
- **Reference** for future troubleshooting
- **Proof** that the setup is working end-to-end

**Note**: This is optional evidence - the system is already verified to be working through the automated verification scripts.
