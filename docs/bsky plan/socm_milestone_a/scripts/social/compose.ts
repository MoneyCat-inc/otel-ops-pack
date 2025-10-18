/* scripts/social/compose.ts
 * Draft builder: appends one JSONL draft to artifacts/social/queue.jsonl
 * ECRR evidence lines written to .agent/EVIDENCE.log
 */
import { appendFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from "fs";
import { dirname } from "path";

type EventType = "plan"|"preflight"|"edit"|"report"|"exit";
function logEvent(who: "A"|"B", type: EventType, msg: string, files=1, loc=1) {
  const line = JSON.stringify({
    t: new Date().toISOString(),
    who, type, lane: "SOCM", files_touched: files, loc_delta: loc, msg
  });
  ensureDir(".agent");
  appendFileSync(".agent/EVIDENCE.log", line + "\n", "utf8");
}

function ensureDir(d: string) {
  try { mkdirSync(d, { recursive: true }); } catch {}
}

function parseArgs() {
  const args = process.argv.slice(2);
  const out: Record<string,string|boolean> = { };
  for (let i=0;i<args.length;i++) {
    const a = args[i];
    if (a.startsWith("--")) {
      const k = a.replace(/^--/,"");
      const v = (i+1 < args.length && !args[i+1].startsWith("--")) ? args[++i] : "true";
      out[k] = v;
    }
  }
  return out;
}

function main() {
  ensureDir("artifacts/social");
  const args = parseArgs();
  const text = (args["text"] as string) || "Hello Bluesky — draft from SOCM lane.";
  const tags = ((args["tags"] as string) || "").split(",").map(s=>s.trim()).filter(Boolean);
  const links = ((args["links"] as string) || "").split(",").map(s=>s.trim()).filter(Boolean);

  logEvent("A","plan","compose draft");

  const draft = {
    id: `d_${Date.now()}`,
    createdAt: new Date().toISOString(),
    kind: "post",
    text, tags, links,
    approved: false,
    posted: false
  };

  const line = JSON.stringify(draft);
  appendFileSync("artifacts/social/queue.jsonl", line + "\n", "utf8");
  logEvent("A","edit",`queued draft ${draft.id}`, 1, 1);
  logEvent("A","report",`draft-ready ${draft.id}`);
  logEvent("A","exit","ok");
}

main();
