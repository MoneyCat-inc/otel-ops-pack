# -*- coding: utf-8 -*-
"""Inspect Firefox quicksuggest-amp.sql - schema and content."""
import sqlite3
import json
import os

path = r"C:\Users\fubum\AppData\Local\Mozilla\Firefox\Profiles\fyoi34av.default-release\remote-settings\quicksuggest-amp.sql"
conn = sqlite3.connect(path)
cur = conn.cursor()

print("=" * 60)
print("SCHEMA (CREATE TABLE)")
print("=" * 60)
cur.execute("SELECT name, sql FROM sqlite_master WHERE type='table' ORDER BY name")
for name, sql in cur.fetchall():
    print(sql)
    print()

print("=" * 60)
print("COLLECTION_METADATA (what this collection is)")
print("=" * 60)
cur.execute("SELECT * FROM collection_metadata")
row = cur.fetchone()
print("collection_url:", row[0])
print("last_modified:", row[1], "(timestamp ms)")
print("bucket:", row[2])
print("signature (first 60):", (row[3] or b"")[:60])
print("x5u (first 60):", (row[4] or b"")[:60] if row[4] else None)

print("\n" + "=" * 60)
print("RECORDS table – what kinds of records")
print("=" * 60)
cur.execute("SELECT id FROM records ORDER BY id LIMIT 20")
ids = [r[0] for r in cur.fetchall()]
for i in ids:
    print(" ", i)
cur.execute("SELECT id FROM records")
all_ids = [r[0] for r in cur.fetchall()]
print("  ... total unique record ids:", len(all_ids))

# One record's data - decode if bytes
cur.execute("SELECT id, data FROM records WHERE id LIKE 'sponsored%' LIMIT 1")
row = cur.fetchone()
if row:
    print("\n  Example record id:", row[0])
    data = row[1]
    if isinstance(data, bytes):
        data = data.decode("utf-8", errors="replace")
    try:
        j = json.loads(data)
        print("  data keys:", list(j.keys()))
        print("  data sample:", json.dumps(j, indent=2)[:600])
    except Exception as e:
        print("  data (first 300 chars):", data[:300])

print("\n" + "=" * 60)
print("ATTACHMENTS table – types and sizes")
print("=" * 60)
cur.execute("SELECT id, length(data) FROM attachments ORDER BY length(data) DESC")
rows = cur.fetchall()
extensions = {}
for aid, size in rows:
    ext = os.path.splitext(aid)[1].lower() or "(no ext)"
    extensions[ext] = extensions.get(ext, 0) + 1
print("  By file extension:", extensions)
print("  Total attachments:", len(rows))
print("  Largest 3:", rows[:3])

# One large JSON attachment (the big ones are .json)
cur.execute("SELECT id, data FROM attachments WHERE id LIKE '%.json' ORDER BY length(data) DESC LIMIT 1")
row = cur.fetchone()
if row:
    print("\n  Example LARGE JSON attachment id:", row[0])
    data = row[1]
    if isinstance(data, bytes):
        data = data.decode("utf-8", errors="replace")
    try:
        j = json.loads(data)
        if isinstance(j, list):
            print("  Root: LIST of %d items (one ad/suggestion per item)" % len(j))
            if len(j) > 0:
                print("  First item keys:", list(j[0].keys()))
                print("  First item sample:", json.dumps(j[0], indent=2)[:1200])
        else:
            print("  Top-level keys:", list(j.keys()))
            for k in list(j.keys())[:8]:
                v = j[k]
                if isinstance(v, list):
                    print("    %s: list len=%d" % (k, len(v)))
                    if len(v) > 0:
                        print("      first item keys:", list(v[0].keys()) if isinstance(v[0], dict) else type(v[0]))
                elif isinstance(v, dict):
                    print("    %s: dict keys=%s" % (k, list(v.keys())[:5]))
                else:
                    print("    %s: %s" % (k, type(v).__name__))
    except Exception as e:
        print("  parse error:", e)
        print("  first 500 chars:", data[:500])

conn.close()
print("\nDone.")
