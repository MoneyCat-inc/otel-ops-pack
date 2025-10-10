#!/usr/bin/env tsx
/**
 * CHAR-2 Actor — PR Commenter
 * - Composes a PR comment from summary.md and labels.json
 * - Posts to GitHub if GITHUB_TOKEN, GITHUB_REPOSITORY, and PR_NUMBER are set
 */

import fs from 'fs'
import path from 'path'

function compose(dir: string): string {
  const sumPath = path.join(dir, 'summary.md')
  const labelsPath = path.join(dir, 'labels.json')
  const summary = fs.existsSync(sumPath) ? fs.readFileSync(sumPath, 'utf-8') : '*No summary available*'
  const labels = fs.existsSync(labelsPath) ? JSON.parse(fs.readFileSync(labelsPath, 'utf-8')) : null
  const lines: string[] = []
  lines.push('## BossCat ECRR Summary')
  lines.push('')
  lines.push('```')
  lines.push(summary.trim())
  lines.push('```')
  if (labels) {
    lines.push('')
    lines.push(`Dominant Class: ${labels.dominant_class} — Rerun Suggested: ${labels.rerun_suggested ? 'Yes' : 'No'}`)
    lines.push('Top Labels:')
    for (const l of labels.labels.slice(0, 5)) {
      const owner = l.owner ? ` | owner: ${l.owner}` : ''
      const play = l.playbook_url ? ` | playbook: ${l.playbook_url}` : ''
      lines.push(`- ${l.component} | ${l.class} | ${l.sig_id} × ${l.count}${owner}${play}`)
    }
  }
  return lines.join('\n') + '\n'
}

async function postToGitHub(repo: string, prNumber: number, body: string, token: string) {
  const url = `https://api.github.com/repos/${repo}/issues/${prNumber}/comments`
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}`, 'User-Agent': 'bosscat-pr-actor', 'Accept': 'application/vnd.github+json' },
    body: JSON.stringify({ body }),
  })
  if (!res.ok) throw new Error(`GitHub comment failed: ${res.status}`)
}

async function main() {
  const args = process.argv.slice(2)
  const dirFlag = args.indexOf('--dir')
  const dir = dirFlag >= 0 ? args[dirFlag + 1] : process.env.RUN_DIR
  if (!dir) { console.error('Usage: tsx scripts/actor-pr-comment.ts --dir <ecrr_run_dir>'); process.exit(2) }
  const body = compose(dir)
  const repo = process.env.GITHUB_REPOSITORY || ''
  const pr = Number(process.env.PR_NUMBER || '0')
  const token = process.env.GITHUB_TOKEN || ''
  if (repo && pr > 0 && token) {
    await postToGitHub(repo, pr, body, token)
    console.log(`Posted PR comment to ${repo}#${pr}`)
  } else {
    console.log('--- PR Comment (dry-run) ---')
    console.log(body)
  }
}

main().catch((e) => { console.error(e); process.exit(1) })
