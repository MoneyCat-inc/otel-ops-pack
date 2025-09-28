# Data Control User Guide

## Overview

The Data Control page gives you complete sovereignty over your practice data. You can export all your practice sessions as a JSON file for backup or analysis, or permanently delete everything if you want to start fresh.

## Key Features

### 📥 **Export Your Data**
- **Complete Export**: Download all practice sessions with metrics, timestamps, and summaries
- **JSON Format**: Standard format compatible with data analysis tools
- **No Audio**: Only metrics and metadata are exported (no audio files)
- **Schema Versioning**: Includes version information for future compatibility

### 🗑️ **Delete All Data**
- **Permanent Removal**: Completely wipe all practice history
- **Confirmation Required**: Must type "DELETE" to confirm
- **Cannot Be Undone**: Deleted data cannot be recovered
- **Local Only**: All deletion happens on your device

## How to Use

### **Exporting Your Data**

1. **Navigate to Data Control**
   - Click "Data Control" in the main navigation
   - View your data summary (sessions, accuracy, comfort)

2. **Export Process**
   - Click "Export as JSON" button
   - File downloads automatically as `resonai_sessions_v1_YYYY-MM-DD.json`
   - Includes all sessions, metrics, and summary statistics

3. **What's Included**
   - **Sessions**: All practice sessions with timestamps
   - **Metrics**: Pitch accuracy, expressiveness, comfort ratings
   - **Summary**: Total sessions, date range, average metrics
   - **Metadata**: Schema version, export date, app version

### **Deleting All Data**

1. **Open Delete Dialog**
   - Click "Delete All Data" button
   - Confirmation modal appears

2. **Confirm Deletion**
   - Type "DELETE" in the confirmation field
   - Click "Delete All" button
   - Wait for completion message

3. **Verification**
   - All practice sessions are permanently removed
   - Data summary shows zero sessions
   - Cannot be undone

## Data Privacy & Security

### **Local-First Architecture**
- **No Uploads**: Your data never leaves your device
- **No Cloud Storage**: Everything stored locally in your browser
- **Complete Control**: You decide what happens to your data

### **Export Privacy**
- **Metrics Only**: No audio files or personal information
- **Structured Data**: Clean JSON format for analysis
- **Versioned**: Schema versioning for future compatibility

### **Delete Privacy**
- **Permanent Removal**: Data is completely wiped from your device
- **No Recovery**: Deleted data cannot be recovered
- **Local Operation**: All deletion happens on your device

## Understanding Your Data

### **Data Summary**
The page shows a summary of your practice data:
- **Practice Sessions**: Total number of recorded sessions
- **Avg Pitch Accuracy**: Average time spent in target pitch range
- **Avg Comfort**: Average comfort rating across sessions

### **Export File Structure**
```json
{
  "schemaVersion": 1,
  "exportedAt": "2024-01-15T10:30:00.000Z",
  "build": "C2-data-control-v1",
  "appVersion": "1.0.0",
  "sessions": [
    {
      "id": 1,
      "ts": 1705312200000,
      "medianF0": 150,
      "inBandPct": 0.7,
      "prosodyVar": 0.5,
      "comfort": 3,
      "schemaVersion": 1
    }
  ],
  "summary": {
    "totalSessions": 10,
    "dateRange": {
      "start": "2024-01-01T00:00:00.000Z",
      "end": "2024-01-15T00:00:00.000Z"
    },
    "metrics": {
      "averageInBandPct": 0.75,
      "averageExpressiveness": 0.55,
      "averageComfort": 3.5
    }
  }
}
```

### **Session Data Fields**
- **id**: Unique session identifier
- **ts**: Timestamp (milliseconds since epoch)
- **medianF0**: Median pitch frequency
- **inBandPct**: Percentage of time in target pitch range
- **prosodyVar**: Expressiveness/variety score
- **voicedTimePct**: Percentage of time with voice activity
- **jitterEma**: Pitch stability measure
- **comfort/fatigue/euphoria**: Subjective ratings (1-5)
- **orb**: Practice type identifier
- **memx**: Advanced metrics (strain, resonance)
- **schemaVersion**: Data format version

## Best Practices

### **Before Deleting**
- **Export First**: Always export your data before deleting
- **Backup Important**: Keep exported files in a safe place
- **Consider Alternatives**: Maybe you just want to start fresh without losing history

### **Export Management**
- **Regular Backups**: Export your data periodically
- **File Organization**: Keep exports organized by date
- **Data Analysis**: Use exported JSON for personal analysis

### **Privacy Considerations**
- **Local Storage**: All data stays on your device
- **No Tracking**: We don't track or analyze your data
- **Complete Control**: You have full control over your information

## Troubleshooting

### **Common Issues**

#### **"No Data to Export"**
- **Cause**: No practice sessions recorded
- **Solution**: Complete a practice session first

#### **"Export Failed"**
- **Cause**: Browser or system error
- **Solution**: Try again or check browser console for errors

#### **"Delete Failed"**
- **Cause**: System error during deletion
- **Solution**: Try again or refresh the page

#### **Modal Won't Close**
- **Cause**: JavaScript error or focus issue
- **Solution**: Refresh the page or press Escape key

### **File Issues**

#### **Can't Open JSON File**
- **Cause**: No JSON viewer installed
- **Solution**: Use a text editor or online JSON viewer

#### **File Seems Corrupted**
- **Cause**: Download interruption
- **Solution**: Try exporting again

#### **Missing Data in Export**
- **Cause**: Data loading error
- **Solution**: Refresh page and try again

## Technical Details

### **Browser Compatibility**
- **Chrome/Edge**: Full support
- **Firefox**: Full support
- **Safari**: Basic support (limited IndexedDB)
- **Mobile**: Responsive design

### **File Formats**
- **Export**: JSON (UTF-8 encoding)
- **Filename**: `resonai_sessions_v{schema}_{date}.json`
- **Size**: Typically 1-10KB per session

### **Data Storage**
- **IndexedDB**: Browser database for session storage
- **Local Only**: No cloud or external storage
- **Persistent**: Data survives browser restarts

## Accessibility Features

### **Screen Reader Support**
- **ARIA Labels**: All buttons and controls properly labeled
- **Live Regions**: Status updates announced automatically
- **Semantic HTML**: Proper heading structure and landmarks

### **Keyboard Navigation**
- **Tab Order**: Logical navigation flow
- **Skip Links**: Quick access to main content
- **Focus Management**: Clear focus indicators

### **Modal Accessibility**
- **Focus Trap**: Keyboard navigation stays within modal
- **Escape Key**: Close modal with Escape key
- **ARIA Attributes**: Proper dialog labeling

## Getting Help

### **Support Resources**
- **Practice Tips**: Check the practice page for guidance
- **Technical Issues**: Review browser console for error messages
- **Feature Requests**: Contact support for enhancement suggestions

### **Data Recovery**
- **Export Backup**: Use exported files to restore data
- **Fresh Start**: Delete and start over if needed
- **Privacy**: All data remains local to your device

---

*The Data Control page ensures you have complete sovereignty over your practice data. Export for backup and analysis, or delete to start fresh - the choice is yours.*
