/* scripts/social/approve.ts
 * Marks the latest draft as approved:true (for human gate usage).
 * ECRR logs to .agent/EVIDENCE.log. This rewrites the last JSONL line for simplicity.
 */
import { readFileSync, writeFileSync, appendFileSync, existsSync, mkdirSync } from "fs";

function ensureDir(d: string) {
  try { mkdirSync(d, { recursive: true }); } catch {}
}

type EventType = "plan"|"edit"|"report"|"exit";
function logEvent(who: "A"|"B", type: EventType, msg: string) {
  ensureDir(".agent");
  const line = JSON.stringify({ t: new Date().toISOString(), who, type, lane: "SOCM", msg });
  appendFileSync(".agent/EVIDENCE.log", line + "\n", "utf8");
}

function main() {
  if (!existsSync("artifacts/social/queue.jsonl")) {
    logEvent("B","report","no queue file; nothing to approve");
    logEvent("B","exit","noop");
    return;
  }
  logEvent("B","plan","approve latest draft");
  const raw = readFileSync("artifacts/social/queue.jsonl","utf8").split("\n");
  let i = raw.length - 1;
  while (i >= 0 && !raw[i].trim()) i--;
  if (i < 0) { logEvent("B","report","no drafts"); logEvent("B","exit","noop"); return; }

  try {
    const lastObj = JSON.parse(raw[i]);
    if (lastObj.kind !== "post") {
      logEvent("B","report",`last line is not a post (${lastObj.kind})`);
      logEvent("B","exit","noop");
      return;
    }
    if (lastObj.posted === true) {
      logEvent("B","report",`draft ${lastObj.id} already posted`);
      logEvent("B","exit","noop");
      return;
    }
    lastObj.approved = true;
    raw[i] = JSON.stringify(lastObj);
    writeFileSync("artifacts/social/queue.jsonl", raw.filter(Boolean).join("\n") + "\n","utf8");
    logEvent("B","edit",`approved draft ${lastObj.id}`);
    logEvent("B","exit","ok");
  } catch (e) {
    logEvent("B","report","cannot parse queue tail; abort");
    logEvent("B","exit","noop");
  }
}

main();
