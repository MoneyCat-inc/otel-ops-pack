/* scripts/social/post.ts
 * Gated poster: reads the latest approved draft from artifacts/social/queue.jsonl
 * If BSKY credentials are present, performs a real post via @atproto/api.
 * Otherwise, performs a DRY-RUN (records intent only).
 * ECRR logs to .agent/EVIDENCE.log and respects .agent/LOCK kill-switch.
 */
import { appendFileSync, existsSync, readFileSync, writeFileSync, appendFileSync as appendFS, mkdirSync } from "fs";

function ensureDir(d: string) {
  try { mkdirSync(d, { recursive: true }); } catch {}
}

type EventType = "plan"|"preflight"|"report"|"exit";
function logEvent(who: "A"|"B", type: EventType, msg: string) {
  ensureDir(".agent");
  const line = JSON.stringify({ t: new Date().toISOString(), who, type, lane: "SOCM", msg });
  appendFileSync(".agent/EVIDENCE.log", line + "\n", "utf8");
}

function loadDrafts(): any[] {
  if (!existsSync("artifacts/social/queue.jsonl")) return [];
  const lines = readFileSync("artifacts/social/queue.jsonl","utf8").split("\n").filter(Boolean);
  const out: any[] = [];
  for (const ln of lines) {
    try { out.push(JSON.parse(ln)); } catch {}
  }
  return out;
}

function latestApprovedUnposted(drafts: any[]): any | null {
  for (let i = drafts.length - 1; i >= 0; i--) {
    const d = drafts[i];
    if (d && d.kind === "post" && d.approved === true && d.posted !== true) return d;
  }
  return null;
}

function sanitizeTags(tags: any): string[] {
  if (!Array.isArray(tags)) return [];
  return tags
    .map((t: any) => String(t||"").trim())
    .filter(Boolean)
    .map((t: string) => {
      const core = t.replace(/^#+/,"");
      return `#${core}`;
    });
}

function joinContent(text: string, tags: string[], links: string[]): string {
  const parts: string[] = [];
  if (text && text.length) parts.push(text.trim());
  if (tags && tags.length) parts.push(tags.join(" "));
  if (links && links.length) parts.push(links.join(" "));
  return parts.join(" ").trim();
}

async function postReal(content: string) {
  const service = process.env.BSKY_SERVICE || "https://bsky.social";
  const handle = process.env.BSKY_HANDLE || "";
  const appPass = process.env.BSKY_APP_PASSWORD || "";
  if (!handle || !appPass) return { uri: "dry-run://missing-credentials" , dryRun: true };

  // Lazy import so script works even if deps not installed yet
  // @ts-ignore
  const { BskyAgent } = await import("@atproto/api");
  const agent = new BskyAgent({ service });
  await agent.login({ identifier: handle, password: appPass });

  const text = content.slice(0, 300); // Bluesky hard cap (approx.)
  // Try modern helper first; fall back to raw record if not available
  try {
    // @ts-ignore
    const out = await agent.post({ text });
    return { uri: out?.uri || "", dryRun: false };
  } catch (e) {
    const did = (agent as any)?.session?.did;
    const record = {
      $type: "app.bsky.feed.post",
      text,
      createdAt: new Date().toISOString()
    };
    // @ts-ignore
    const out2 = await agent.api.com.atproto.repo.createRecord({
      repo: did,
      collection: "app.bsky.feed.post",
      record
    });
    return { uri: out2?.uri || "", dryRun: false };
  }
}

function appendPostedLedger(entry: any) {
  appendFS("artifacts/social/posted.jsonl", JSON.stringify(entry) + "\n", "utf8");
}

async function main() {
  logEvent("A","preflight","start post");
  if (existsSync(".agent/LOCK")) {
    logEvent("A","report","kill-switch present; abort");
    process.exit(50);
  }

  const drafts = loadDrafts();
  const d = latestApprovedUnposted(drafts);
  if (!d) { logEvent("A","report","no approved drafts"); logEvent("A","exit","noop"); return; }

  const tags = sanitizeTags(d.tags || []);
  const links = Array.isArray(d.links) ? d.links.map((s:any)=>String(s).trim()).filter(Boolean) : [];
  const content = joinContent(String(d.text||""), tags, links);

  const res = await postReal(content);
  const ledger = {
    postedAt: new Date().toISOString(),
    draftId: d.id,
    handle: process.env.BSKY_HANDLE || "",
    bskyUri: res.uri,
    dryRun: res.dryRun === true,
    text: content
  };
  appendPostedLedger(ledger);
  
  // Mark draft as posted in queue to prevent double-posting
  d.posted = true;
  d.postedAt = ledger.postedAt;
  const queueLines = readFileSync("artifacts/social/queue.jsonl", "utf8").split("\n");
  for (let i = queueLines.length - 1; i >= 0; i--) {
    if (!queueLines[i].trim()) continue;
    try {
      const obj = JSON.parse(queueLines[i]);
      if (obj.id === d.id) {
        queueLines[i] = JSON.stringify(d);
        break;
      }
    } catch {}
  }
  writeFileSync("artifacts/social/queue.jsonl", queueLines.filter(Boolean).join("\n") + "\n", "utf8");
  
  logEvent("A","report", (res.dryRun ? "dry-run " : "") + `posted ${d.id} → ${res.uri || "no-uri"}`);
  logEvent("A","exit","ok");
}

main().catch(err => {
  logEvent("A","report","error: " + (err?.message || String(err)));
  process.exit(1);
});
