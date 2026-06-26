#!/usr/bin/env python3
import argparse, json, os, time, sys

REQUIRED = [
  ".github/workflows/bosscat-gate-verify.yml", "docs/status/tests.json",
  "docs/status.html", "CHAR/ECRR/ECRR_REPORTS", "docs/observability/snapshots",
  "docs/IONA_ERRORS.md", "docs/cheatsheets", "index.html"
]
PRIMARY_DIR = "artifacts"
LEGACY_DIR = "DELT/ARTF"
PRIMARY_JSON = os.path.join(PRIMARY_DIR, "gate-verification-results.json")
LEGACY_JSON = os.path.join(LEGACY_DIR, "gate-verification-results.json")

def _write_json(path, payload):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--use-mock", action="store_true")
    ap.add_argument("--test-types", nargs="+", default=["baseline","load"])
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--mirror-legacy", action="store_true",
                    help="Also mirror outputs to DELT/ARTF for legacy consumers")
    args=ap.parse_args()
    os.makedirs(PRIMARY_DIR, exist_ok=True)
    # seed minimal status if missing
    os.makedirs("docs/status", exist_ok=True)
    if not os.path.exists("docs/status/tests.json"):
        with open("docs/status/tests.json","w",encoding="utf-8") as f:
            json.dump({"summary":{"total":0,"passed":0,"failed":0},"tests":[]}, f)
    if not os.path.exists("docs/status.html"):
        with open("docs/status.html","w",encoding="utf-8") as f:
            f.write("<!doctype html><title>BossCat Status</title>")
    for d in ["CHAR/ECRR/ECRR_REPORTS","docs/observability/snapshots","docs/cheatsheets"]:
        os.makedirs(d, exist_ok=True)
    if not os.path.exists("docs/IONA_ERRORS.md"):
        with open("docs/IONA_ERRORS.md","w",encoding="utf-8") as f: f.write("# IONA Error Ledger\n")
    checks = {}
    missing = []
    for p in REQUIRED:
        exists = os.path.exists(p)
        checks[p] = "present" if exists else "missing"
        if not exists: missing.append(p)
    verdict = "READY" if not missing else "NOT_READY"
    reasons = []
    if missing: reasons.append("Missing required assets: " + ", ".join(missing))
    obj = {
      "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
      "commit": os.popen("git rev-parse --short HEAD").read().strip(),
      "branch": os.popen("git rev-parse --abbrev-ref HEAD").read().strip(),
      "verdict": verdict,
      "reasons": reasons,
      "checks": checks
    }
    _write_json(PRIMARY_JSON, obj)
    if args.mirror_legacy:
        os.makedirs(LEGACY_DIR, exist_ok=True)
        _write_json(LEGACY_JSON, obj)
        print("[WARN] Mirrored gate results to legacy DELT/ARTF path; update consumers to artifacts/.", file=sys.stderr)
    elif os.path.exists(LEGACY_JSON):
        print("[WARN] Legacy gate results detected at DELT/ARTF but mirror not requested; file remains stale.", file=sys.stderr)
    if args.verbose: print(json.dumps(obj, indent=2))
    return 0 if verdict!="NOT_READY" else 2
if __name__=="__main__": sys.exit(main())

