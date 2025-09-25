#!/usr/bin/env node
import fs from 'fs';
import path from 'path';

const REPORTS_DIR = path.join(process.cwd(), 'docs', 'ECRR_REPORTS');
const INDEX_MD = path.join(REPORTS_DIR, 'INDEX.md');
const INDEX_JSON = path.join(REPORTS_DIR, 'index.json');

// Parse front matter (very small parser)
function parseFrontMatter(text) {
  const m = text.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n/);
  if (!m) return {};
  const yaml = m[1].split(/\r?\n/).reduce((acc, line) => {
    const mm = line.match(/^([A-Za-z0-9_]+):\s*(.*)$/);
    if (!mm) return acc;
    const k = mm[1].trim();
    let v = mm[2].trim();
    v = v.replace(/^"(.*)"$/, '$1'); // strip quotes
    acc[k] = v;
    return acc;
  }, {});
  return yaml;
}

function isReportName(f) {
  return /^ECRR-\d{8}-\d{6}(?:-[A-Z0-9-]+)?\.md$/.test(f);
}

function loadReports() {
  const files = fs.readdirSync(REPORTS_DIR).filter(isReportName);
  const reports = [];
  for (const file of files) {
    const p = path.join(REPORTS_DIR, file);
    const raw = fs.readFileSync(p, 'utf8');
    const fm = parseFrontMatter(raw);
    const key = fm.ecrr_key || file.replace(/\.md$/, '');
    const timestamp = fm.timestamp_utc || '';
    const scope = fm.scope || '';
    const outcome = fm.outcome || '';
    const branch = fm.branch || '';
    const commit = fm.commit || '';
    reports.push({ key, file, timestamp, scope, outcome, branch, commit });
  }
  // Sort desc by timestamp
  reports.sort((a, b) => (a.timestamp < b.timestamp ? 1 : -1));
  return reports;
}

function writeIndexMd(reports) {
  const rows = reports.map(r =>
    `| [${r.key}](./${r.file}) | ${r.timestamp} | ${r.scope} | ${r.outcome} | ${r.branch} | \`${r.commit}\` |`
  ).join('\n');

  const md =
`# ECRR Reports Index

> Canonical index of all ECRR reports. Sorted by \`timestamp_utc\` (desc).

| Key | Timestamp (UTC) | Scope | Outcome | Branch | Commit |
|-----|------------------|-------|---------|--------|--------|
${rows || ''}
`;
  fs.writeFileSync(INDEX_MD, md, 'utf8');
}

function writeIndexJson(reports) {
  fs.writeFileSync(INDEX_JSON, JSON.stringify(reports, null, 2), 'utf8');
}

function writeLatestMd(reports) {
  if (!reports.length) return;
  const r = reports[0];
  const LATEST_MD = path.join(REPORTS_DIR, 'LATEST.md');
  const latest = `# Latest ECRR

- **Key:** [${r.key}](./${r.file})
- **When:** ${r.timestamp}
- **Outcome:** ${r.outcome}
- **Scope:** ${r.scope}

[View full index →](./INDEX.md)
`;
  fs.writeFileSync(LATEST_MD, latest, 'utf8');
}

function main() {
  if (!fs.existsSync(REPORTS_DIR)) {
    console.error(`Missing ${REPORTS_DIR}`);
    process.exit(1);
  }
  const reports = loadReports();
  writeIndexMd(reports);
  writeIndexJson(reports);
  writeLatestMd(reports);
  console.log(`Indexed ${reports.length} ECRR reports.`);
}

main();
