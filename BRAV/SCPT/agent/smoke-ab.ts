// scripts/agent/smoke-ab.ts
// run with: pnpm agent:smoke:ssot   (or any lane)
import fs from "fs";
import path from "path";

const ROOT = process.cwd();
const LOCK = path.join(ROOT, ".agent", "LOCK");
const REG  = path.join(ROOT, ".agent", "bots.json");
const ECRR = path.join(ROOT, "docs", "ecrr", "ECRR_REPORTS");

type Bot = { code: string; title?: string; lane?: string; role?: string };

function die(msg: string, code = 1): never { console.error("❌", msg); process.exit(code); }

async function ecrrNote(context: string, message: string): Promise<void> {
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, -5);
  const filename = `SMOKE_AB_${context}_${timestamp}.md`;
  const filepath = path.join(ECRR, filename);
  
  const content = `# A/B Smoke Test Failure

**Context:** ${context}  
**Timestamp:** ${new Date().toISOString()}  
**Status:** ❌ FAILED

## Issue

${message}

## ECRR

- **Examine:** A/B pair validation during smoke test
- **Clean:** Pairing failed - bot registry may be incomplete
- **Report:** This automated note
- **Role:** Tetragram smoke test validator

## Action Required

Check \`.agent/bots.json\` for missing ALFA or BETA pair in lane ${context.split(":")[1] || "UNKNOWN"}.

---

*Automated ECRR note from smoke-ab.ts*
`;

  try {
    if (!fs.existsSync(ECRR)) fs.mkdirSync(ECRR, { recursive: true });
    fs.writeFileSync(filepath, content, "utf8");
    console.error(`📝 ECRR note written: ${filepath}`);
  } catch (err) {
    console.error(`⚠️  Could not write ECRR note: ${err}`);
  }
}

async function preflight(set: string, lane: string, role: string): Promise<void> {
  // Kill-switch check
  if (fs.existsSync(LOCK)) {
    die(".agent/LOCK present — global pause engaged (kill‑switch).");
  }

  // Registry exists?
  if (!fs.existsSync(REG)) {
    die("Missing .agent/bots.json (registry).");
  }
}

async function pairUp(lane: string, role: string): Promise<void> {
  const raw = JSON.parse(fs.readFileSync(REG, "utf8"));
  const bots: Bot[] = Array.isArray(raw) ? raw : (raw.bots || []);
  
  // Find partner
  const partnerRole = role === "ALFA" ? "BETA" : "ALFA";
  const expectedSet = role === "ALFA" ? "AUTO-BOTS" : "IONA-CATS";
  const partnerSet = partnerRole === "ALFA" ? "AUTO-BOTS" : "IONA-CATS";
  
  const self = bots.find(b => b.code === `${expectedSet}-${lane}-${role}`);
  const partner = bots.find(b => b.code === `${partnerSet}-${lane}-${partnerRole}`);
  
  if (!self) {
    throw new Error(`Missing self bot: ${expectedSet}-${lane}-${role}`);
  }
  
  if (!partner) {
    throw new Error(`Missing partner bot: ${partnerSet}-${lane}-${partnerRole}`);
  }
  
  console.log(`✓ Found pair: ${self.code} ↔ ${partner.code}`);
}

const lane = process.argv[2]?.toUpperCase() || "SSOT";

(async () => {
  try {
    // Writer side
    await preflight("AUTO-BOTS", lane, "ALFA");
    await pairUp(lane, "ALFA");
    // Monitor side (simulated)
    await preflight("IONA-CATS", lane, "BETA");
    await pairUp(lane, "BETA");
    console.log(`✅ A/B handshake healthy for lane ${lane}.`);
  } catch (e: any) {
    await ecrrNote(`smoke-ab:${lane}`, `Pairing failed: ${String(e?.message ?? e)}`);
    process.exit(2);
  }
})();

