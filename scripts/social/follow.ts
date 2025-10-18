/* scripts/social/follow.ts
 * Declarative follow applier (dry-run by default).
 * Reads docs/social/FOLLOW_LIST.yaml and prints intended actions.
 */
import { readFileSync } from "fs";
import * as yaml from "yaml";

function main() {
  const y = readFileSync("docs/social/FOLLOW_LIST.yaml","utf8");
  const doc = yaml.parse(y);
  const apply = process.argv.includes("--apply");
  const items: {handle:string, reason?:string}[] = [];
  for (const k of Object.keys(doc||{})) {
    const arr = doc[k]||[];
    for (const it of arr) items.push({handle: it.handle, reason: it.reason});
  }
  if (items.length === 0) { console.log("No handles."); return; }
  console.log(apply ? "APPLY: will follow" : "DRY-RUN: would follow");
  for (const it of items) console.log(` - @${it.handle}  # ${it.reason||""}`);
  if (apply) {
    console.log("NOTE: Network follow via ATProto is plugged in at Milestone B.");
  }
}

main();
