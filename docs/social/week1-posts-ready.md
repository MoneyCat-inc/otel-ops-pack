# Week-1 Posts - Ready to Post
**All under 300 chars, with placeholders marked**

---

## Wed Oct 23 (09:00 UTC) — Mythbuster

**Char count:** 228

```
❌ Myth: "One screenshot = proof."
✅ Fact: Screens can be altered. Check source, date, context. Do a quick reverse-image search. Ask for a link to the original.
Reply "CHECKLIST" for our 60-sec workflow.
```

**To post:**
```bash
npx tsx scripts/social/post-content.ts "❌ Myth: \"One screenshot = proof.\"\n✅ Fact: Screens can be altered. Check source, date, context. Do a quick reverse-image search. Ask for a link to the original.\nReply \"CHECKLIST\" for our 60-sec workflow."
```

---

## Thu Oct 24 (18:00 UTC) — Method Thread 1/3

**Char count:** 142

```
1/3 How we verify claims fast:
• Define the claim exactly
• Source (primary vs. commentary)
• Date (current or old?)
• Context (what's omitted?)
Thread 👇
```

---

## Thu Oct 24 (18:02 UTC) — Method Thread 2/3

**Char count:** 164  
**Reply to:** Previous post (1/3)

```
2/3 Cross-checks:
• Search the exact phrasing in quotes
• Reverse image search if visuals
• Look for primary docs (.gov, court filings)
```

---

## Thu Oct 24 (18:04 UTC) — Method Thread 3/3

**Char count:** 159  
**Reply to:** Previous post (2/3)

```
3/3 Outcomes:
• Correct • Needs context • Misleading • False • Unverified
We always cite sources. Send us a claim to audit.
```

---

## Fri Oct 25 (09:00 UTC) — Weekly Recap

**Char count:** 234

```
🗂️ This week's patterns:
• Old stories shared as new
• Cropped images hiding context
• Anonymous screenshots w/ no links
If you see these, pause before reposting. Send us candidates to check.
```

---

## Sat Oct 26 (10:00 UTC) — Community Spotlight

**Char count:** ~200 (depends on placeholders)  
**ACTION REQUIRED:** Replace `<account>`, `<1 sentence>`, `<link>`

```
☀️ Spotlight: @<account> — consistent, sourced debunks.
Why it's good: <1 sentence>.
Recent example: <link> (credit the work; avoid dunking)
```

**Example (if spotlighting Full Fact):**
```
☀️ Spotlight: @fullfact.org — consistent, sourced debunks.
Why it's good: Fast UK policy corrections with primary sources.
Recent example: https://fullfact.org/... (credit the work; avoid dunking)
```

---

## Sun Oct 27 (18:00 UTC) — Signal Boost (Quote Post)

**Char count:** ~150 (depends on context)  
**ACTION REQUIRED:** Quote-post someone's good work, add 1-2 lines

```
Adding context: <1-2 lines about what they got right or what to add>.
Read their sources; keep receipts.
Good work, @<source>.
```

**Example:**
```
Adding context: This debunk cites both AFP and Full Fact independently. That's the standard.
Read their sources; keep receipts.
Good work, @politifact.bsky.social.
```

---

## 🤖 Automated Posting Script

Create `scripts/social/post-week1.ts`:

```typescript
#!/usr/bin/env tsx
import { BskyAgent, RichText } from '@atproto/api';
import * as dotenv from 'dotenv';
import * as path from 'path';

dotenv.config({ path: path.join(process.cwd(), '.env.socm') });

const agent = new BskyAgent({ service: process.env.BSKY_SERVICE || 'https://bsky.social' });

async function postWithDelay(text: string, delayMs = 0) {
  if (delayMs > 0) await new Promise(r => setTimeout(r, delayMs));
  
  const rt = new RichText({ text });
  await rt.detectFacets(agent);
  
  const post = await agent.post({
    text: rt.text,
    facets: rt.facets,
    createdAt: new Date().toISOString(),
  });
  
  console.log(`✅ Posted: ${post.uri.split('/').pop()}`);
  return post;
}

async function main() {
  await agent.login({
    identifier: process.env.BSKY_HANDLE!,
    password: process.env.BSKY_APP_PASSWORD!,
  });
  
  console.log('✅ Logged in\n');
  
  // Post all week-1 content
  // Wed - Mythbuster
  await postWithDelay(`❌ Myth: "One screenshot = proof."
✅ Fact: Screens can be altered. Check source, date, context. Do a quick reverse-image search. Ask for a link to the original.
Reply "CHECKLIST" for our 60-sec workflow.`);
  
  // Thu - Method thread (create all 3, linked)
  const thread1 = await postWithDelay(`1/3 How we verify claims fast:
• Define the claim exactly
• Source (primary vs. commentary)
• Date (current or old?)
• Context (what's omitted?)
Thread 👇`, 2000);
  
  const thread2 = await agent.post({
    text: `2/3 Cross-checks:
• Search the exact phrasing in quotes
• Reverse image search if visuals
• Look for primary docs (.gov, court filings)`,
    reply: {
      root: { uri: thread1.uri, cid: thread1.cid },
      parent: { uri: thread1.uri, cid: thread1.cid },
    },
  });
  console.log(`✅ Posted reply: ${thread2.uri.split('/').pop()}`);
  
  await new Promise(r => setTimeout(r, 2000));
  
  const thread3 = await agent.post({
    text: `3/3 Outcomes:
• Correct • Needs context • Misleading • False • Unverified
We always cite sources. Send us a claim to audit.`,
    reply: {
      root: { uri: thread1.uri, cid: thread1.cid },
      parent: { uri: thread2.uri, cid: thread2.cid },
    },
  });
  console.log(`✅ Posted reply: ${thread3.uri.split('/').pop()}`);
  
  // Fri - Weekly recap
  await postWithDelay(`🗂️ This week's patterns:
• Old stories shared as new
• Cropped images hiding context
• Anonymous screenshots w/ no links
If you see these, pause before reposting. Send us candidates to check.`, 2000);
  
  console.log('\n✅ All posts created! Sat/Sun posts require manual placeholders.');
}

main();
```

**Usage:** Save above as `scripts/social/post-week1.ts`, then run when ready to post.

---

## 📅 Scheduling Options

### Option A: Post Now (Immediate)
```bash
npx tsx scripts/social/post-week1.ts
```
Posts all automated content immediately. Sat/Sun posts need manual creation.

### Option B: Schedule in Buffer
1. Import `docs/social/week1-buffer-import.csv`
2. Replace placeholders manually
3. Set times per the schedule

### Option C: Native Bluesky Scheduling (if available)
Check if Bluesky has native scheduling in Settings → Posts

---

## ⏰ Optimal Posting Times (UTC)

| Day | Time | Post Type |
|-----|------|-----------|
| Wed | 09:00 | Mythbuster |
| Thu | 18:00 | Method thread (3 posts) |
| Fri | 09:00 | Weekly recap |
| Sat | 10:00 | Community spotlight (manual) |
| Sun | 18:00 | Signal boost quote (manual) |

**Why these times:**
- 09:00 UTC = US East Coast morning (high engagement)
- 18:00 UTC = EU evening + US afternoon (peak overlap)
- 10:00 UTC = Weekend browsing time

---

## 🎯 Manual Posts (Sat/Sun)

These require real-time content (current debunks, community highlights):

**Saturday Template:**
```
☀️ Spotlight: @<find-good-account-this-week> — consistent, sourced debunks.
Why it's good: <specific observation>.
Recent example: <link-to-their-post>
```

**Sunday Template:**
```
Adding context: <what-they-verified-well>.
Read their sources; keep receipts.
Good work, @<tag-the-source>.
```

*Quote-post a high-quality debunk from that week and add your 2 cents.*

---

**Status:** Automation ready for Wed-Fri posts. Sat-Sun require manual curation (good practice for staying current!).

