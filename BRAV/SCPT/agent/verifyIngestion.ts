import { execFileSync } from "node:child_process";
function run(cmd: string, args: string[]) { execFileSync(cmd, args, { stdio: "inherit" }); }

const sigUrl = process.env.SIGNOZ_URL ?? "http://localhost:8080";
const service = process.env.SERVICE_NAME ?? "synthetic-windows-check";

console.log(`[BossCat] Verifying ingestion → ${sigUrl} for ${service}`);
run("python", ["synthetic/send_synthetic_otel_simple.py"]);
run("pwsh", ["-File", "scripts/verify-synthetic-ingestion-enhanced.ps1", "-SigNozUrl", sigUrl, "-ServiceName", service]);
run("pnpm", ["playwright", "test", "scripts/signoz-snapshot.spec.ts"]);
console.log(`[BossCat] Ingestion verified; evidence written to artifacts/`);
