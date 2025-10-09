// scripts/agent/validate-tetragram.ts
// run with: pnpm agent:validate-names
import fs from "fs";
import path from "path";

const ROOT = process.cwd();
const LOCK = path.join(ROOT, ".agent", "LOCK");
const REG  = path.join(ROOT, ".agent", "bots.json");

const LANES = new Set(["SSOT","FLAK","SELE","COMP","DOCS"]);
const RE_4  = /^[A-Z]{4}$/;

function die(msg: string, code = 1): never { console.error("❌", msg); process.exit(code); }

if (fs.existsSync(LOCK)) die(".agent/LOCK present — global pause engaged (kill‑switch).");

if (!fs.existsSync(REG)) die("Missing .agent/bots.json (registry).");

type Bot = { code: string; title?: string; lane?: string; role?: string };
const raw = JSON.parse(fs.readFileSync(REG, "utf8"));
const bots: Bot[] = Array.isArray(raw) ? raw : (raw.bots || []);

if (!Array.isArray(bots) || bots.length === 0) die("Empty bots registry.");

const errs: string[] = [];
const seen = new Set<string>();
const perLane: Record<string, { ALFA: number; BETA: number }> = {};

for (const b of bots) {
  const code = b.code?.trim();
  if (!code) { errs.push("Missing code field."); continue; }

  if (seen.has(code)) errs.push(`Duplicate code: ${code}`);
  seen.add(code);

  const parts = code.split("-");
  if (parts.length !== 4) { errs.push(`Not 4-4-4-4: ${code}`); continue; }

  const [P1, P2, P3, P4] = parts;
  if (![P1, P2, P3, P4].every(p => RE_4.test(p))) errs.push(`Non‑tetragram segment in ${code}`);

  // SET-SET
  if (!((P1 === "AUTO" && P2 === "BOTS") || (P1 === "IONA" && P2 === "CATS")))
    errs.push(`SET must be AUTO‑BOTS or IONA‑CATS: ${code}`);

  // LANE
  if (!LANES.has(P3)) errs.push(`Invalid LANE '${P3}' in ${code}`);

  // ROLE
  if (!(P4 === "ALFA" || P4 === "BETA")) errs.push(`ROLE must be ALFA or BETA (NATO spelling): ${code}`);

  // Writer/Monitor discipline
  if (P4 === "ALFA" && !(P1 === "AUTO" && P2 === "BOTS"))
    errs.push(`ALFA must belong to AUTO‑BOTS: ${code}`);
  if (P4 === "BETA" && !(P1 === "IONA" && P2 === "CATS"))
    errs.push(`BETA must belong to IONA‑CATS: ${code}`);

  // Count pairs
  if (LANES.has(P3) && (P4 === "ALFA" || P4 === "BETA")) {
    perLane[P3] ??= { ALFA: 0, BETA: 0 };
    (perLane[P3] as any)[P4]++;
  }
}

// Pair completeness
for (const lane of LANES) {
  const c = perLane[lane] ?? { ALFA: 0, BETA: 0 };
  if (c.ALFA !== 1 || c.BETA !== 1)
    errs.push(`Lane ${lane}: require exactly one ALFA and one BETA (found A=${c.ALFA}, B=${c.BETA}).`);
}

if (errs.length) {
  console.error("— Validation errors —");
  for (const e of errs) console.error(" •", e);
  die(`Tetragram validation failed with ${errs.length} error(s).`);
}

console.log("✅ Tetragram registry valid (4‑4‑4‑4; lanes ok; A/B pairs complete).");

