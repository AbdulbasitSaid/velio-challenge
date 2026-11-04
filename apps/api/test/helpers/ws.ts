import type { ServerMessage } from '@velio/contracts';

/** A realtime test client: records every message, close code and ping. */
export interface WsClient {
  messages: ServerMessage[];
  pings: number;
  send(msg: unknown): void;
  sendRaw(data: string): void;
  /** Resolves with the first message matching `pred`, including messages already received. */
  waitFor(pred: (m: ServerMessage) => boolean, timeoutMs?: number): Promise<ServerMessage>;
  closed: Promise<number>;
  close(): void;
}

export function connectWs(
  baseUrl: string,
  options: { platform?: string; query?: string; headers?: Record<string, string> } = {},
): Promise<WsClient> {
  const query = options.query ?? `platform=${options.platform ?? 'web'}`;
  const url = `${baseUrl.replace(/^http/, 'ws')}/api/ws?${query}`;
  // Bun's client accepts upgrade headers (cookie, bearer), as Flutter's does.
  const ws = new WebSocket(url, { headers: options.headers ?? {} } as unknown as string[]);
  const messages: ServerMessage[] = [];
  const waiters: { pred: (m: ServerMessage) => boolean; resolve: (m: ServerMessage) => void }[] = [];
  let resolveClosed: (code: number) => void;
  const closed = new Promise<number>((r) => (resolveClosed = r));
  const client: WsClient = {
    messages,
    pings: 0,
    send: (msg) => ws.send(JSON.stringify(msg)),
    sendRaw: (data) => ws.send(data),
    waitFor(pred, timeoutMs = 5_000) {
      const seen = messages.find(pred);
      if (seen) return Promise.resolve(seen);
      return new Promise((resolve, reject) => {
        const timer = setTimeout(() => reject(new Error('timed out waiting for a message')), timeoutMs);
        waiters.push({
          pred,
          resolve: (m) => {
            clearTimeout(timer);
            resolve(m);
          },
        });
      });
    },
    closed,
    close: () => ws.close(),
  };
  ws.addEventListener('message', (e) => {
    const msg = JSON.parse(String(e.data)) as ServerMessage;
    messages.push(msg);
    for (let i = waiters.length - 1; i >= 0; i--) {
      if (waiters[i]!.pred(msg)) waiters.splice(i, 1)[0]!.resolve(msg);
    }
  });
  ws.addEventListener('ping' as never, () => client.pings++);
  ws.addEventListener('close', (e) => resolveClosed(e.code));
  return new Promise((resolve, reject) => {
    ws.addEventListener('open', () => resolve(client));
    ws.addEventListener('error', () => reject(new Error('websocket failed to open')));
  });
}
