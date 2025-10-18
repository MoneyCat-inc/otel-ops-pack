/* scripts/social/icf-lesson-intake.ts
 * Reads last mini-retro from evidence log and suggests next improvement (≤10 LOC)
 * Lane: SOCM | Suggest-only (no auto-apply)
 */
import { readFileSync } from 'fs';

const lines = readFileSync('.agent/EVIDENCE.log','utf8').split('\n').filter(Boolean);
const last = lines.slice(-10).reverse().find(l => {
  try { return JSON.parse(l).msg?.includes('needs-tuning'); } catch { return false; }
});

if (last) {
  const msg = JSON.parse(last).msg || '';
  const tuning = msg.match(/needs-tuning:\s*(.+)/)?.[1] || 'all-green';
  console.log(`📝 ICF Suggestion (from last retro): ${tuning}`);
  console.log('   → Review and apply manually (suggest-only)');
} else {
  console.log('ℹ️ No tuning suggestions found in recent evidence');
}

