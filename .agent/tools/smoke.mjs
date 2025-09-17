import { execSync } from "node:child_process";
const cmd = (c) => execSync(c, { stdio: "inherit", env: process.env });

try {
  console.log("SMOKE: Starting observability pipeline tests...");
  
  // Test 1: Validate collector configuration
  try {
    cmd('powershell -NoProfile -Command "& \'C:\\Program Files\\OpenTelemetry Collector\\otelcol-contrib.exe\' validate --config config.yaml"');
    console.log("✓ Collector config validation passed");
  } catch (e) {
    console.error("✗ Collector config validation failed:", e.message);
    throw e;
  }
  
  // Test 2: Check if collector is running
  try {
    cmd('powershell -NoProfile -Command "Test-NetConnection -ComputerName localhost -Port 5318"');
    console.log("✓ Collector port 5318 is accessible");
  } catch (e) {
    console.error("✗ Collector port 5318 not accessible:", e.message);
    throw e;
  }
  
  // Test 3: Check if SigNoz is running
  try {
    cmd('powershell -NoProfile -Command "Test-NetConnection -ComputerName localhost -Port 8080"');
    console.log("✓ SigNoz port 8080 is accessible");
  } catch (e) {
    console.error("✗ SigNoz port 8080 not accessible:", e.message);
    throw e;
  }
  
  // Test 4: Run simple test
  try {
    cmd('powershell -NoProfile -Command ".\\simple-test.ps1"');
    console.log("✓ Simple test passed");
  } catch (e) {
    console.error("✗ Simple test failed:", e.message);
    throw e;
  }
  
  console.log("SMOKE: All tests passed ✅");
  process.exit(0);
} catch (e) {
  console.error("SMOKE FAILED", e?.message || e);
  process.exit(1);
}

