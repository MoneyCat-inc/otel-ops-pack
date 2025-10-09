import { describe, it, expect } from "vitest";
import { summarize, type MemxSnapshot } from "../scripts/memx/normalize";

describe("MEMX normalize", () => {
  it("summarizes last snapshot", () => {
    const snap = {
      version: "memx-1",
      snapshot_id: "abc",
      ts: "2025-09-28T12:00:00.000Z",
      host: "D-MONOLITH",
      system: { 
        total_ram_bytes: 32 * 1024 * 1024 * 1024, 
        free_ram_bytes: 20 * 1024 * 1024 * 1024, 
        committed_bytes: 18 * 1024 * 1024 * 1024 
      },
      pagefile: null,
      processes: [],
      containers: []
    } as MemxSnapshot;

    const summary = summarize([snap])!;
    expect(summary.host).toBe("D-MONOLITH");
    expect(summary.ram_used_pct).toBeGreaterThan(0);
    expect(summary.committed_over_ram).toBe(false);
  });

  it("handles empty snapshots array", () => {
    const summary = summarize([]);
    expect(summary).toBeNull();
  });

  it("calculates RAM usage percentage correctly", () => {
    const snap = {
      version: "memx-1",
      snapshot_id: "test",
      ts: "2025-09-28T12:00:00.000Z",
      host: "TEST-HOST",
      system: { 
        total_ram_bytes: 1000, 
        free_ram_bytes: 300, 
        committed_bytes: 800 
      },
      pagefile: null,
      processes: [],
      containers: []
    } as MemxSnapshot;

    const summary = summarize([snap])!;
    expect(summary.ram_used_pct).toBe(70.0); // (1000-300)/1000 * 100
  });
});
