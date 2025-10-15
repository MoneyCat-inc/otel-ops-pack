#!/usr/bin/env node
// BRAV/SCPT/rsi/propose.mjs — Generate a candidate patch (params only)
import { createReadStream, existsSync } from 'node:fs';
import { resolve } from 'node:path';
import readline from 'node:readline';

const ROOT = resolve(process.cwd());
const MET_INDEX = resolve(ROOT, 'CHAR/EVID/artifacts/ecrr/index/METRICS.jsonl');
const MET_ARCH = resolve(ROOT, 'CHAR/EVID/artifacts/ecrr/arch/METRICS.jsonl');

async function readLast(file) {
  if (!existsSync(file)) return null;
  let last = null;
  const rl = readline.createInterface({ input: createReadStream(file, 'utf8'), crlfDelay: Infinity });
  for await (const line of rl) {
    if (!line.trim()) continue; try { last = JSON.parse(line) } catch {}
  }
  return last;
}

(async () => {
  const lastIndex = await readLast(MET_INDEX);
  const lastArch = await readLast(MET_ARCH);

  const currIdxConc = Number(lastIndex?.params?.IndexConcurrency ?? 8);
  const currBatch = Number(lastIndex?.params?.BatchSize ?? 1000);
  const currQps = Number(lastArch?.params?.ARCH_QPS ?? 2.0);
  const currConc = Number(lastArch?.params?.ARCH_CONCURRENCY ?? 48);

  // Simple hill climb: nudge up concurrency if no errors observed
  const candidate = {
    index: {
      IndexConcurrency: Math.min(currIdxConc + 2, 64),
      BatchSize: currBatch
    },
    conveyor: {
      ARCH_QPS: Math.min(Number((currQps + 0.3).toFixed(1)), 10.0),
      ARCH_CONCURRENCY: Math.min(currConc + 8, 128)
    }
  };

  process.stdout.write(JSON.stringify(candidate));
})();

