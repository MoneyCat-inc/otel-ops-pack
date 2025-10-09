#!/usr/bin/env python3
import argparse, json, os, time, sys, urllib.request
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--verbose", action="store_true")
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
    os.makedirs("DELT/ARTF", exist_ok=True)
    with open("DELT/ARTF/otlp-smoke.json","w",encoding="utf-8") as f: json.dump(result,f,indent=2)
    if args.verbose: print(json.dumps(result, indent=2))
    return 0
if __name__=="__main__": sys.exit(main())
