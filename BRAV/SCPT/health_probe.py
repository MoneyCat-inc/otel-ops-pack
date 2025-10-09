#!/usr/bin/env python3
import json, sys, urllib.request
URL = "http://localhost:13134/healthz"
try:
    with urllib.request.urlopen(URL, timeout=5) as r:
        body = r.read().decode("utf-8", errors="ignore")
        print(json.dumps({"ok": r.status == 200, "status": r.status, "body": body, "target": URL}))
        sys.exit(0 if r.status == 200 else 3)
except Exception as e:
    print(json.dumps({"ok": False, "error": str(e), "target": URL}))
    sys.exit(3)

