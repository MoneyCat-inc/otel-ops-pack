/* scripts/social/post.ts
 * Gated poster: reads last approved draft from queue and (dry-run) posts.
 * Real network call is plugged in at Milestone B.
 */
import { appendFileSync, existsSync, readFileSync, writeFileSync } from "fs";

type EventType = "plan"|"preflight"|"report"|"exit";
function logEvent(who: "A"|"B", type: EventType, msg: string) {
  const line = JSON.stringify({ t: new Date().toISOString(), who, type, lane: "SOCM", msg });
  appendFileSync(".agent/EVIDENCE.log", line + "\n", "utf8");
}

function readLastDraft(): any | null {
  if (!existsSync("artifacts/social/queue.jsonl")) return null;
  const data = readFileSync("artifacts/social/queue.jsonl","utf8").trim().split("\n").filter(Boolean);
  if (data.length === 0) return null;
  try { return JSON.parse(data[data.length-1]); } catch { return null; }
}

function appendPosted(rec: any) {
  const line = JSON.stringify(rec);
  appendFileSync("artifacts/social/posted.jsonl", line + "\n","utf8");
}

function main() {
  logEvent("A","preflight","start post");
  if (existsSync(".agent/LOCK")) {
    logEvent("A","report","kill-switch present; abort");
    process.exit(50);
  }

  const handle = process.env.BSKY_HANDLE || "";
  const appPass = process.env.BSKY_APP_PASSWORD || "";
  if (!handle || !appPass) {
    logEvent("A","report","missing BSKY credentials; dry-run only");
  }

  const d = readLastDraft();
  if (!d) { logEvent("A","report","no drafts"); logEvent("A","exit","noop"); return; }
  if (!d.approved) { logEvent("A","report",`draft ${d.id} not approved; noop`); logEvent("A","exit","noop"); return; }

  // Milestone A: DRY-RUN – do not hit network. Record intent & ledger.
  const posted = {
    postedAt: new Date().toISOString(),
    draftId: d.id,
    handle,
    bskyUri: "dry-run://not-posted",
    text: d.text,
    tags: d.tags||[]
  };
  appendPosted(posted);
  logEvent("A","report",`dry-run posted ${d.id}`);
  logEvent("A","exit","ok");
}

main();
