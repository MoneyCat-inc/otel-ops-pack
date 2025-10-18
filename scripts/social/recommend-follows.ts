// Reads curated FOLLOW_LIST.yaml + current follow ledger (if any)
// Emits ranked SUGGESTIONS only (no auto-follow).
// Usage: tsx scripts/social/recommend-follows.ts --out artifacts/social/follow_suggestions.jsonl
import { promises as fs } from 'fs';
import path from 'path';
import YAML from 'yaml';

type Curated = { handle:string; rationale?:string; topics?:string[] }[];
type Suggest = { handle:string; score:number; reasons:string[]; action:'follow_suggested' };

const now = () => new Date().toISOString();
const OUT = (process.argv[process.argv.indexOf('--out')+1]) || 'artifacts/social/follow_suggestions.jsonl';

async function readYaml(p:string){ return YAML.parse(await fs.readFile(p,'utf8')); }
async function safeReadLines(p:string){ try{ return (await fs.readFile(p,'utf8')).trim().split('\n'); }catch{ return []; } }

(async () => {
  if (await fs.stat('.agent/LOCK').then(()=>true).catch(()=>false)) process.exit(50);
  await fs.appendFile('.agent/EVIDENCE.log', JSON.stringify({t:now(),who:'A',type:'plan',lane:'SOCM',msg:'recommend follows'})+'\n');

  const curated:Curated = await readYaml('docs/social/FOLLOW_LIST.yaml') || [];
  const already = new Set<string>(
    (await safeReadLines('artifacts/social/followed.jsonl'))
      .map(l => { try{ return JSON.parse(l).handle as string; }catch{ return ''; } })
      .filter(Boolean)
  );

  // Simple scoring: curated entries you don't yet follow rise to top.
  // Bonus weights if topics align with known tags (from TAGS.yaml).
  const tagsDoc = await readYaml('docs/social/TAGS.yaml') || {};
  const approved = new Set<string>((tagsDoc.approved||[]).map((t:any)=>String(t).toLowerCase()));

  const suggestions:Suggest[] = curated
    .filter(c => !already.has(c.handle))
    .map(c => {
      const reasons = ['curated:list'];
      let score = 0.8;
      const hit = (c.topics||[]).some(t => approved.has(String(t||'').toLowerCase()));
      if (hit) { score += 0.15; reasons.push('topic:approved'); }
      if ((c.rationale||'').toLowerCase().includes('observab')) { score += 0.05; reasons.push('obs-focus'); }
      return { handle: c.handle, score: Math.min(0.99, score), reasons, action:'follow_suggested' as const };
    })
    .sort((a,b)=>b.score-a.score);

  await fs.mkdir(path.dirname(OUT), { recursive:true });
  await fs.writeFile(OUT, suggestions.map(s=>JSON.stringify(s)).join('\n') + '\n', 'utf8');
  await fs.appendFile('.agent/EVIDENCE.log', JSON.stringify({t:now(),who:'A',type:'report',lane:'SOCM',msg:`emitted ${suggestions.length} follow suggestions`})+'\n');
  await fs.appendFile('.agent/EVIDENCE.log', JSON.stringify({t:now(),who:'A',type:'exit',lane:'SOCM',msg:'ok'})+'\n');
})();

