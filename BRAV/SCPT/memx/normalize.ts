import fs from "node:fs";
import path from "node:path";

export type MemxSnapshot = {
  version: "memx-1";
  snapshot_id: string;
  ts: string;
  host: string;
  system: { 
    total_ram_bytes: number; 
    free_ram_bytes: number; 
    committed_bytes: number; 
  };
  pagefile: null | { 
    allocated_mb: number; 
    current_mb: number; 
    peak_mb: number; 
    name: string; 
  };
  processes: Array<{ 
    name: string; 
    pid: number; 
    working_set_bytes: number; 
    private_mem_bytes: number; 
    cpu_total_ms: number; 
  }>;
  containers: Array<{ 
    id: string; 
    name: string; 
    cpu_pct: number; 
    mem_used_bytes: number|null; 
    mem_limit_bytes: number|null; 
    mem_pct: number; 
    oom_killed: boolean; 
  }>;
};

export function clamp<T extends number>(n: T, min: number, max: number): number {
  return Math.min(Math.max(n, min), max);
}

export function loadLatest(dir = ".artifacts/memx/snapshots", limit = 50): MemxSnapshot[] {
  if (!fs.existsSync(dir)) return [];
  const files = fs.readdirSync(dir)
    .filter(f => f.endsWith(".json"))
    .sort()
    .slice(-limit);
  return files.map(f => JSON.parse(fs.readFileSync(path.join(dir, f), "utf8")));
}

export function summarize(snaps: MemxSnapshot[]) {
  const last = snaps.at(-1);
  if (!last) return null;
  const used = last.system.total_ram_bytes - last.system.free_ram_bytes;
  return {
    ts: last.ts,
    host: last.host,
    ram_used_pct: Math.round((used / last.system.total_ram_bytes) * 1000) / 10,
    committed_over_ram: last.system.committed_bytes > last.system.total_ram_bytes
  };
}
