/**
 * Syncs artifacts/loose-ends-tracker.md Status column from issues labeled "Loose-End".
 * Mapping:
 *   - issue.state === "closed" -> "Done"
 *   - issue.state === "open" && has assignees -> "In Progress"
 *   - otherwise -> "Not Started"
 * It matches table rows by Title substring (row[1]) within issue.title.
 *
 * Usage: node scripts/sync-loose-ends-tracker.js --repo <owner/repo>
 */
const fs = require('fs');
const path = require('path');

const GITHUB_TOKEN = process.env.GITHUB_TOKEN;
const repoArg = process.argv.find(a => a.startsWith('--repo'));
const REPO = repoArg ? repoArg.split('=')[1] || process.argv[process.argv.indexOf(repoArg) + 1] : process.env.REPO;
if (!GITHUB_TOKEN || !REPO) {
  console.error('Missing GITHUB_TOKEN or --repo <owner/repo>');
  process.exit(1);
}

const TRACKER = path.join(process.cwd(), 'artifacts', 'loose-ends-tracker.md');

async function gh(pathname, params = {}) {
  const url = new URL(`https://api.github.com/repos/${REPO}/${pathname}`);
  if (params.search) Object.entries(params.search).forEach(([k, v]) => url.searchParams.set(k, v));
  const res = await fetch(url, {
    headers: {
      authorization: `Bearer ${GITHUB_TOKEN}`,
      accept: 'application/vnd.github+json',
      'x-github-api-version': '2022-11-28',
      'user-agent': 'loose-ends-sync',
    },
  });
  if (!res.ok) {
    const t = await res.text();
    throw new Error(`GitHub API ${pathname} failed: ${res.status} ${t}`);
  }
  return res.json();
}

async function listAllIssues() {
  const perPage = 100;
  let page = 1;
  const all = [];
   
  while (true) {
    const data = await gh('issues', {
      search: {
        state: 'all',
        labels: 'Loose-End',
        per_page: String(perPage),
        page: String(page),
      },
    });
    all.push(...data);
    if (data.length < perPage) break;
    page += 1;
  }
  return all;
}

function parseTable(md) {
  const lines = md.split('\n');
  const start = lines.findIndex(line => /^\|\s*#\s*\|/i.test(line));
  if (start === -1) return { lines, start: -1, end: -1, rows: [] };

  let end = start + 1;
  while (end < lines.length && (/^\|/.test(lines[end]) || lines[end].trim() === '')) end += 1;

  const rows = [];
  for (let i = start + 2; i < end; i += 1) {
    const line = lines[i];
    if (!/^\|/.test(line)) continue;
    const cols = line.split('|').slice(1, -1).map(col => col.trim());
    if (cols.length < 6) continue;
    rows.push({ idx: i, cols });
  }
  return { lines, start, end, rows };
}

function updateStatusFromIssues(rows, issues) {
  const norm = s => s.toLowerCase().replace(/\s+/g, ' ').trim();
  
  for (const row of rows) {
    const stableId = row.cols[0]; // e.g., "LE-01"
    const title = row.cols[1];
    const titleNorm = norm(title);
    
    // First try to match by stable ID in issue title
    let match = issues.find(issue => {
      return issue.title.includes(`[${stableId}]`) || issue.title.includes(stableId);
    });
    
    // Fallback to title substring matching if no ID match
    if (!match) {
      match = issues.find(issue => {
        const t = norm(issue.title);
        return t.includes(titleNorm) || titleNorm.includes(t);
      });
    }
    
    if (!match) continue;

    let newStatus = 'Not Started';
    if (match.state === 'closed') newStatus = 'Done';
    else if (match.state === 'open' && match.assignees && match.assignees.length > 0) newStatus = 'In Progress';

    row.cols[3] = newStatus;
    
    // Update owner if issue has assignees
    if (match.assignees && match.assignees.length > 0) {
      row.cols[4] = match.assignees.map(a => a.login).join(', ');
    }
  }
}

function serialize({ lines, rows }) {
  for (const row of rows) {
    const out = `| ${row.cols[0]} | ${row.cols[1]} | ${row.cols[2]} | ${row.cols[3]} | ${row.cols[4]} | ${row.cols[5]} |`;
    lines[row.idx] = out;
  }
  return lines.join('\n');
}

(async function main() {
  const md = fs.readFileSync(TRACKER, 'utf8');
  const parsed = parseTable(md);
  if (parsed.start === -1) {
    console.log('Tracker table not found; no changes.');
    return;
  }
  const issues = await listAllIssues();
  updateStatusFromIssues(parsed.rows, issues);
  const output = serialize(parsed);
  if (output !== md) {
    fs.writeFileSync(TRACKER, output, 'utf8');
    console.log('Tracker updated from issues.');
  } else {
    console.log('No changes to tracker.');
  }
})().catch(err => {
  console.error(err);
  process.exit(1);
});
