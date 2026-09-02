#!/usr/bin/env tsx
/**
 * AUTO-BOTS Tetragram Setup
 * Generates registry, badges, and roster with 4-4-4-4 naming
 * 
 * Grammar: SET-SET-LANE-ROLE
 * Writers: AUTO-BOTS-<LANE>-ALFA
 * Monitors: IONA-CATS-<LANE>-BETA
 * 
 * Exit Codes:
 * - 0: Success
 * - 50: Kill-switch active
 * - 1: Setup error
 */

import fs from "fs/promises";
import path from "path";

type Role = "ALFA" | "BETA";
type Lane = "SSOT" | "FLAK" | "SELE" | "COMP" | "DOCS";

type Bot = {
  code: string;          // e.g., AUTO-BOTS-SSOT-ALFA
  set: "AUTO-BOTS" | "IONA-CATS";
  role: Role;            // ALFA (writer) | BETA (monitor)
  lane: Lane;            // SSOT/FLAK/SELE/COMP/DOCS
  title: string;
  task: string;
  badge: { file: string; label: string; emoji: string; color: string };
};

const ROOT = process.cwd();
const KILL = path.join(ROOT, ".agent", "LOCK");
const BADGES = path.join(ROOT, "docs", "BossCat", "badges");
const AGENTS_MD = path.join(ROOT, "docs", "BossCat", "AGENTS.md");
const REGISTRY = path.join(ROOT, ".agent", "bots.json");

function tetragram(...parts: string[]) {
  for (const p of parts) {
    if (p.length !== 4 || !/^[A-Z]{4}$/.test(p)) {
      throw new Error(`Invalid tetragram '${p}'. Must be 4 A–Z capitals.`);
    }
  }
  return parts.join("-");
}

function nameFor(set: "AUTO-BOTS" | "IONA-CATS", lane: Lane, role: Role) {
  const [a, b] = set.split("-"); // e.g., AUTO, BOTS or IONA, CATS
  return tetragram(a, b, lane, role);
}

const BOTS: Bot[] = [
  { set: "AUTO-BOTS", role: "ALFA", lane: "SSOT", title: "SSOT Refresher",
    task: "Regenerate SSOT and RUN_AND_VERIFY.md",
    badge: { file: "auto-bots-ssot-alfa.svg", label: "AUTO-SSOT-ALFA", emoji: "&#x1FAB6;", color: "#4C9AFF" } },
  { set: "IONA-CATS", role: "BETA", lane: "SSOT", title: "SSOT Auditor",
    task: "Verify docs-only diffs, ECRR, BOSSCAT_LOG",
    badge: { file: "iona-cats-ssot-beta.svg", label: "IONA-SSOT-BETA", emoji: "&#x1FAB6;", color: "#7FB3FF" } },

  { set: "AUTO-BOTS", role: "ALFA", lane: "FLAK", title: "Flaky Test Quarantiner",
    task: "Mark @flaky/skip and isolate",
    badge: { file: "auto-bots-flak-alfa.svg", label: "AUTO-FLAK-ALFA", emoji: "&#x1F9EA;", color: "#FFAB00" } },
  { set: "IONA-CATS", role: "BETA", lane: "FLAK", title: "Test Stability Watch",
    task: "Validate scope (tests), collect evidence",
    badge: { file: "iona-cats-flak-beta.svg", label: "IONA-FLAK-BETA", emoji: "&#x1F9EA;", color: "#FFCC66" } },

  { set: "AUTO-BOTS", role: "ALFA", lane: "SELE", title: "Selector Hygienist",
    task: "Add data-testid + small ARIA",
    badge: { file: "auto-bots-sele-alfa.svg", label: "AUTO-SELE-ALFA", emoji: "&#x1F3AF;", color: "#6554C0" } },
  { set: "IONA-CATS", role: "BETA", lane: "SELE", title: "Selector Inspector",
    task: "Check allowed files; ensure tests green",
    badge: { file: "iona-cats-sele-beta.svg", label: "IONA-SELE-BETA", emoji: "&#x1F3AF;", color: "#8E7FE0" } },

  { set: "AUTO-BOTS", role: "ALFA", lane: "COMP", title: "Security & A11y Fixer",
    task: "Remove inline scripts/styles; add a11y metadata",
    badge: { file: "auto-bots-comp-alfa.svg", label: "AUTO-COMP-ALFA", emoji: "&#x1F6E1;", color: "#36B37E" } },
  { set: "IONA-CATS", role: "BETA", lane: "COMP", title: "Compliance Auditor",
    task: "Validate CSP/WCAG AA; ECRR trail",
    badge: { file: "iona-cats-comp-beta.svg", label: "IONA-COMP-BETA", emoji: "&#x1F6E1;", color: "#7AD0AE" } },

  { set: "AUTO-BOTS", role: "ALFA", lane: "DOCS", title: "Docs Synchronizer",
    task: "Refresh docs/runbooks to match reality",
    badge: { file: "auto-bots-docs-alfa.svg", label: "AUTO-DOCS-ALFA", emoji: "&#x1F4DA;", color: "#00B8D9" } },
  { set: "IONA-CATS", role: "BETA", lane: "DOCS", title: "Docs Proofreader",
    task: "Lint/consistency; BOSSCAT_LOG + gate",
    badge: { file: "iona-cats-docs-beta.svg", label: "IONA-DOCS-BETA", emoji: "&#x1F4DA;", color: "#5CD7EA" } },
].map(b => ({ ...b, code: nameFor(b.set, b.lane, b.role) }));

function svgBadge(label: string, emoji: string, color: string) {
  const w = Math.max(140, 16 + label.length * 8);
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="28" role="img" aria-label="${label}">
  <rect rx="6" width="${w}" height="28" fill="${color}"/>
  <g font-family="ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto" font-size="12" fill="#fff">
    <text x="10" y="18">${emoji}</text>
    <text x="36" y="18">${label}</text>
  </g>
</svg>`;
}

async function exists(p: string) { try { await fs.access(p); return true; } catch { return false; } }
async function ensureDir(p: string) { await fs.mkdir(p, { recursive: true }); }

(async function main() {
  console.log("🐾 AUTO-BOTS Tetragram Setup");
  console.log("─".repeat(50));

  // Kill-switch check
  if (await exists(KILL)) {
    console.error("❌ [setup-bots] paused:lock — .agent/LOCK present; aborting.");
    process.exit(50);
  }
  console.log("✅ Kill-switch: Clear");

  // Create directories
  await ensureDir(path.dirname(REGISTRY));
  await ensureDir(BADGES);
  console.log("✅ Directories prepared");

  // Generate badges
  console.log("\n📛 Generating badges...");
  await Promise.all(BOTS.map(async b => {
    const svg = svgBadge(b.badge.label, b.badge.emoji, b.badge.color);
    await fs.writeFile(path.join(BADGES, b.badge.file), svg, "utf8");
    console.log(`   ✓ ${b.badge.file}`);
  }));

  // Generate registry
  console.log("\n📋 Generating registry...");
  const registry = {
    generatedAt: new Date().toISOString(),
    grammar: "SET-SET-LANE-ROLE (4-4-4-4 tetragrams)",
    writers: "AUTO-BOTS-*-ALFA",
    monitors: "IONA-CATS-*-BETA",
    bots: BOTS,
  };
  await fs.writeFile(REGISTRY, JSON.stringify(registry, null, 2));
  console.log(`   ✓ ${path.relative(ROOT, REGISTRY)}`);

  // Generate roster
  console.log("\n📚 Generating roster...");
  const rows = BOTS.map(b =>
    `| <img src="./badges/${b.badge.file}" alt="${b.badge.label}" height="20"/> | **${b.code}** | ${b.title} | \`${b.lane}\` | ${b.role} | ${b.task} |`
  ).join("\n");

  const md = `# 🐾 AUTO-BOTS Registry (Tetragram Edition)

**Grammar:** SET-SET-LANE-ROLE (4-4-4-4)  
**Writers:** AUTO-BOTS-*-ALFA (Agent A - modifies files)  
**Monitors:** IONA-CATS-*-BETA (Agent B - reads only, validates)

> Budgets & lanes enforced; kill-switch respected; gate signal: **\`@cat ready-for-gate\`**

---

## The Ten Bots

| Badge | Bot Code | Title | Lane | Role | Task |
|---|---|---|---|---|---|
${rows}

---

## Lane Definitions

| Lane Code | Full Name | Purpose | Allow Patterns |
|-----------|-----------|---------|----------------|
| **SSOT** | Single Source of Truth | Artifact refresh | \`**/.artifacts/**\`, \`**/RUN_AND_VERIFY.md\` |
| **FLAK** | Flaky Tests | Test quarantine | \`**/tests/**\`, \`**/playwright/**\` |
| **SELE** | Selector Hygiene | Test stability | \`**/components/**\`, \`**/tests/**\` |
| **COMP** | Compliance | Security & A11y | \`**/*.html\`, \`**/*.tsx\`, \`**/*.ts\` |
| **DOCS** | Documentation | Docs drift | \`**/docs/**\`, \`README.md\` |

---

## Usage

### Run Writer (AUTO-BOTS-*-ALFA)
\`\`\`bash
pnpm agent:run:ssot      # AUTO-BOTS-SSOT-ALFA
pnpm agent:run:flaky     # AUTO-BOTS-FLAK-ALFA
pnpm agent:run:selector  # AUTO-BOTS-SELE-ALFA
pnpm agent:run:comp      # AUTO-BOTS-COMP-ALFA
pnpm agent:run:docs      # AUTO-BOTS-DOCS-ALFA
\`\`\`

### Monitor (IONA-CATS-*-BETA)
\`\`\`bash
# IONA-CATS bots read artifacts/ecrr/<lane>/*.json
# Validate ECRR structure, check budgets, append BOSSCAT_LOG
# Never modify files or acquire locks
\`\`\`

---

## Tetragram Rules

1. **4 letters per segment** - AUTO, BOTS, SSOT, ALFA
2. **Hyphen-separated** - AUTO-BOTS-SSOT-ALFA
3. **All uppercase** - No lowercase allowed
4. **NATO spelling for roles** - ALFA (not ALPHA), BETA

---

## Evidence Trail

Every bot run generates:
- **ECRR artifact:** \`artifacts/ecrr/<lane>/<timestamp>.json\`
- **BossCat log entry:** \`docs/BossCat/BOSSCAT_LOG.md\` (one-liner)
- **Gate signal:** \`@cat ready-for-gate\` in PR when ready

---

**Last updated:** ${new Date().toISOString()}  
**Generated by:** \`BRAV/SCPT/agent/setup-bots.ts\` (run: \`pnpm tsx BRAV/SCPT/agent/setup-bots.ts\`)  
**Authority:** 🐾 BossCat OEM (Executive Overseer Manager)
`;

  await fs.writeFile(AGENTS_MD, md, "utf8");
  console.log(`   ✓ ${path.relative(ROOT, AGENTS_MD)}`);

  console.log("\n─".repeat(50));
  console.log("✅ Tetragram setup complete!");
  console.log("\n📍 Generated:");
  console.log(`   Registry: ${path.relative(ROOT, REGISTRY)}`);
  console.log(`   Badges:   ${path.relative(ROOT, BADGES)}`);
  console.log(`   Roster:   ${path.relative(ROOT, AGENTS_MD)}`);
  console.log("\n🐾 BossCat OEM - 10 bots registered in 4-4-4-4 format");
})().catch(e => { 
  console.error("❌ Setup failed:", e); 
  process.exit(1); 
});

