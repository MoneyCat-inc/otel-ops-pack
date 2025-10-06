export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

// API Health Check Endpoint (super minimal Response)
// GET /api/health

export async function GET() {
  try {
    const body = JSON.stringify({ status: 'ok' });
    return new Response(body, { status: 200, headers: { 'content-type': 'application/json' } });
  } catch {
    return new Response(JSON.stringify({ status: 'unhealthy' }), { status: 500, headers: { 'content-type': 'application/json' } });
  }
}