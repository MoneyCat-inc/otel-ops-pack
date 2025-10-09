import { execSync } from "node:child_process";
function sh(cmd: string) { execSync(cmd, { stdio: "inherit" }); }

const sigUrl = process.env.SIGNOZ_URL ?? "http://localhost:8080";
const service = process.env.SERVICE_NAME ?? "synthetic-windows-check";

console.log(`[BossCat] Verifying ingestion → ${sigUrl} for ${service}`);
sh(`python synthetic/send_synthetic_otel_simple.py`);
sh(`pwsh -File scripts/verify-synthetic-ingestion-enhanced.ps1 -SigNozUrl ${sigUrl} -ServiceName ${service}`);
sh(`pnpm playwright test scripts/signoz-snapshot.spec.ts`);
console.log(`[BossCat] Ingestion verified; evidence written to artifacts/`);
