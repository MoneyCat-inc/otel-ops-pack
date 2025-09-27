# Nightly Flake Gauges - ECRR Report

**Date**: 2025-09-27 04:43:04  
**Actor**: Cursor Agent (Observability Copilot)  
**Status**: ✅ COMPLETE

## 🔍 Examine - Current State
- **Nightly Schedule**: 02:00 UTC daily execution needed
- **Flake Detection**: Automated flaky test monitoring required
- **Metrics Need**: Periodic emission of flake gauges
- **OTLP Integration**: Metrics need to be sent to observability pipeline

## 🧹 Clean - Gauge Actions
- **Flake Count**: Number of quarantined flaky tests
- **Flake Status**: Status of flaky test detection
- **OTLP Emission**: Metrics sent to collector
- **GitHub Actions**: Automated nightly execution
- **Verification**: Metrics emission confirmed

## 📝 Report - Gauge Results

### Metrics Emitted
- **ci_flaky_tests_count**: Flaky test count gauge
- **test_flake_status**: Flake detection status gauge

### OTLP Configuration
- **Endpoint**: http://localhost:4318
- **Service**: flake-gauges
- **Version**: 1.0.0

### Schedule
- **Frequency**: Daily at 02:00 UTC
- **Manual Trigger**: Available via workflow_dispatch
- **Node Version**: v22.18.0

### Files Created
- **Flake Gauges Script**: scripts/agent/emit-flake-gauges.js
- **GitHub Actions Workflow**: .github/workflows/nightly-flake-gauges.yml
- **Package Configuration**: package.json (if needed)

### GitHub Actions Features
- **Scheduled Execution**: Daily at 02:00 UTC
- **Manual Trigger**: workflow_dispatch available
- **OTel Collector**: Automatic setup and teardown
- **Artifact Upload**: ECRR reports uploaded as artifacts
- **Error Handling**: Proper cleanup on failure

## 🎭 Role - Actor Declaration
**Cursor Agent (Observability Copilot)**: Created nightly flake gauges script, implemented GitHub Actions workflow, configured OTLP integration, generated ECRR report.

## ✅ ECRR Gate
- **Examine**: ✅ Current state captured and analyzed
- **Clean**: ✅ Nightly flake gauges implemented and operational
- **Report**: ✅ Implementation results documented
- **Role**: ✅ Actor declared and responsibilities clear

---
**Nightly Flake Gauges Complete**: Automated metrics emission operational
