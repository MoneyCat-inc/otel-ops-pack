#!/usr/bin/env python3
import argparse, json, os, time, sys, urllib.request

PRIMARY_DIR = "artifacts"
LEGACY_DIR = "DELT/ARTF"
PRIMARY_PATH = os.path.join(PRIMARY_DIR, "otlp-smoke.json")
LEGACY_PATH = os.path.join(LEGACY_DIR, "otlp-smoke.json")

def _write(path, payload):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--mirror-legacy", action="store_true",
                    help="Also mirror results to DELT/ARTF for legacy consumers")
    args=ap.parse_args()
    result={"ts":time.strftime("%Y-%m-%dT%H:%M:%S%z"),
            "sigNozUrl": os.environ.get("SIGNOZ_URL","http://localhost:8080"),
            "status":"unknown"}
    try:
        with urllib.request.urlopen(result["sigNozUrl"], timeout=3) as r:
            result["status"]="ok" if r.status<500 else "degraded"
    except Exception as e:
        result["status"]="unreachable"
        result["error"]=str(e)
    _write(PRIMARY_PATH, result)
    if args.mirror_legacy:
        _write(LEGACY_PATH, result)
        print("[WARN] Mirrored OTLP smoke results to legacy DELT/ARTF path; update consumers to artifacts/.", file=sys.stderr)
    elif os.path.exists(LEGACY_PATH):
        print("[WARN] Legacy OTLP smoke results detected in DELT/ARTF but mirror not requested; file left untouched.", file=sys.stderr)
    if args.verbose: print(json.dumps(result, indent=2))
    return 0
if __name__=="__main__": sys.exit(main())
