#!/usr/bin/env python3
import argparse, json, os, time, sys
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--gate-results", required=True)
    ap.add_argument("--output", required=True)
    ap.add_argument("--pdf", required=False)
    args=ap.parse_args()
    with open(args.gate_results, "r", encoding="utf-8") as f:
        data=json.load(f)
    lines=[
      "# ECRR CI Report", "",
      f"Timestamp: {time.strftime('%Y-%m-%d %H:%M:%S %z')}",
      f"Commit: {data.get('commit','')}",
      f"Branch: {data.get('branch','')}", "",
      f"Verdict: {data.get('verdict','')}", ""
    ]
    for k,v in (data.get("checks") or {}).items():
        lines.append(f"- {k}: {v}")
    os.makedirs(os.path.dirname(args.output) or ".", exist_ok=True)
    with open(args.output,"w",encoding="utf-8") as f: f.write("\n".join(lines))
    if args.pdf:
        # Placeholder: write textual content with .pdf extension
        with open(args.pdf,"w",encoding="utf-8") as f: f.write("\n".join(lines))
    return 0
if __name__=="__main__": sys.exit(main())
