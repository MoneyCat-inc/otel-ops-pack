// ICF Heuristic 01 — Retry-on-slow-UI Smoke
// Reusable polling helper for UI readiness checks

export async function waitReady<T>(
  check: () => Promise<T | null>,
  opts: { retries?: number; delayMs?: number; enabled?: boolean } = {}
): Promise<T | null> {
  const { retries = 30, delayMs = 3000, enabled = process.env.SMOKE_WAIT_READY !== "false" } = opts;
  
  if (!enabled) return check();
  
  for (let i = 0; i < retries; i++) {
    const result = await check();
    if (result) return result;
    await new Promise((r) => setTimeout(r, delayMs));
  }
  return null;
}



