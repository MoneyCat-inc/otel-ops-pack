export function getSigNozUrl(): string {
  return process.env.SIGNOZ_URL || 'http://localhost:8080';
}

export async function healthCheck(fetchImpl: typeof fetch): Promise<boolean> {
  try {
    const res = await fetchImpl(getSigNozUrl(), { method: 'GET' });
    return res.status < 500;
  } catch {
    return false;
  }
}

