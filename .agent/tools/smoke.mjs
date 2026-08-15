import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function loadOtelPorts() {
  let dir = __dirname;
  for (;;) {
    const candidate = path.join(dir, "DELT", "CONF", "otel-ports.json");
    if (fs.existsSync(candidate)) {
      return JSON.parse(fs.readFileSync(candidate, "utf8"));
    }
    const parent = path.dirname(dir);
    if (parent === dir) throw new Error("otel-ports.json not found");
    dir = parent;
  }
}

const ports = loadOtelPorts();
const ingestHttp = ports.windows_collector_ingest.http;
const signozUi = ports.signoz_ui.http;

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
    cmd(`powershell -NoProfile -Command "Test-NetConnection -ComputerName localhost -Port ${ingestHttp}"`);
    console.log(`✓ Collector port ${ingestHttp} is accessible`);
  } catch (e) {
    console.error(`✗ Collector port ${ingestHttp} not accessible:`, e.message);
    throw e;
  }
  
  // Test 3: Check if SigNoz is running
  try {
    cmd(`powershell -NoProfile -Command "Test-NetConnection -ComputerName localhost -Port ${signozUi}"`);
    console.log(`✓ SigNoz port ${signozUi} is accessible`);
  } catch (e) {
    console.error(`✗ SigNoz port ${signozUi} not accessible:`, e.message);
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
