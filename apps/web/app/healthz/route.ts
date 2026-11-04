// Liveness for the Compose healthcheck: no data, exempt from the origin check (proxy.ts).
export const dynamic = 'force-dynamic';

export function GET() {
  return Response.json({ status: 'ok' });
}
