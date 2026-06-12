import sqlite3
path = r"C:\Users\fubum\AppData\Local\Mozilla\Firefox\Profiles\fyoi34av.default-release\remote-settings\quicksuggest-amp.sql"
conn = sqlite3.connect(path)
cur = conn.cursor()
cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
tables = [r[0] for r in cur.fetchall()]
print("Tables:", tables)
for t in tables:
    cur.execute("SELECT COUNT(*) FROM [%s]" % t)
    n = cur.fetchone()[0]
    cur.execute("PRAGMA table_info([%s])" % t)
    cols = cur.fetchall()
    print("  %s: %d rows, columns: %s" % (t, n, [c[1] for c in cols]))
    if n > 0:
        cur.execute("SELECT * FROM [%s] LIMIT 2" % t)
        for row in cur.fetchall():
            preview = str(row)[:120] + "..." if len(str(row)) > 120 else str(row)
            print("    sample: %s" % preview)
cur.execute("PRAGMA page_count")
pages = cur.fetchone()[0]
cur.execute("PRAGMA page_size")
ps = cur.fetchone()[0]
cur.execute("PRAGMA freelist_count")
free = cur.fetchone()[0]
print("Pages: %d, page_size: %d -> logical ~%.1f MB" % (pages, ps, pages*ps/1024/1024))
print("Freelist pages (reclaimable): %d (~%.1f MB)" % (free, free*ps/1024/1024))
conn.close()
