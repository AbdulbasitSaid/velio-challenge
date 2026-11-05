// Typed fetch for the API (S5 §4.5). The contracts package already exports every schema, so there is no
// generated client: callers pass the response schema, and errors become ApiRequestError with a typed code.
// Browser code imports only types from @velio/contracts: its schemas would put Zod in every page's JS (S6 §4.8).
import type { ErrorCode, ErrorEnvelope } from '@velio/contracts';
import type { z } from 'zod';
import { DEVICE_COOKIE, DEVICE_HEADER } from '../device';

export class ApiRequestError extends Error {
  constructor(
    readonly status: number,
    readonly code: ErrorCode | 'network',
    message: string,
    readonly requestId?: string,
  ) {
    super(message);
    this.name = 'ApiRequestError';
  }
}

export interface ApiInit<S extends z.ZodType | undefined> {
  method?: 'GET' | 'POST' | 'PATCH' | 'PUT' | 'DELETE';
  body?: unknown;
  /** Response schema. Parsed in development and tests; trusted in production builds (bundle and CPU). */
  schema?: S;
  /** Reused across retries of one attempt (PRD Edge cases: server error). */
  idempotencyKey?: string;
  headers?: Record<string, string>;
  signal?: AbortSignal;
  /** Lets the request outlive the page (analytics sent while it hides, S8). */
  keepalive?: boolean;
}

type Result<S> = S extends z.ZodType ? z.infer<S> : undefined;

/** Base URL and extra headers; the server variant (./server) forwards the viewer's request context. */
export interface Transport {
  baseUrl: string;
  headers: () => Promise<Record<string, string>> | Record<string, string>;
}

const strict = process.env.NODE_ENV !== 'production';

export async function request<S extends z.ZodType | undefined = undefined>(
  transport: Transport,
  path: string,
  init: ApiInit<S> = {},
): Promise<Result<S>> {
  const headers: Record<string, string> = {
    accept: 'application/json',
    ...(await transport.headers()),
    ...init.headers,
  };
  if (init.body !== undefined) headers['content-type'] = 'application/json';
  if (init.idempotencyKey) headers['idempotency-key'] = init.idempotencyKey;

  let res: Response;
  try {
    res = await fetch(`${transport.baseUrl}/api${path}`, {
      method: init.method ?? 'GET',
      headers,
      body: init.body === undefined ? undefined : JSON.stringify(init.body),
      credentials: 'same-origin',
      cache: 'no-store',
      signal: init.signal,
      keepalive: init.keepalive,
    });
  } catch (err) {
    if ((err as Error).name === 'AbortError') throw err;
    throw new ApiRequestError(0, 'network', 'Network request failed');
  }

  if (!res.ok) {
    const body = (await res.json().catch(() => null)) as Partial<ErrorEnvelope> | null;
    const error = body?.error;
    if (error && typeof error.code === 'string' && typeof error.message === 'string') {
      throw new ApiRequestError(res.status, error.code, error.message, error.requestId);
    }
    throw new ApiRequestError(res.status, 'internal', `HTTP ${res.status}`);
  }
  if (res.status === 204) return undefined as Result<S>;
  const text = await res.text();
  if (!text) return undefined as Result<S>;
  const json: unknown = JSON.parse(text);
  // Without a schema the body is returned unchecked (browser code: no Zod in the bundle, S6 §4.8).
  return (strict && init.schema ? init.schema.parse(json) : json) as Result<S>;
}

function readCookie(name: string): string | undefined {
  if (typeof document === 'undefined') return undefined;
  const match = document.cookie.split('; ').find((c) => c.startsWith(`${name}=`));
  return match?.slice(name.length + 1);
}

/** Browser transport: same origin, session cookie sent automatically, device ID from its cookie. */
export const browser: Transport = {
  baseUrl: '',
  headers: (): Record<string, string> => {
    const device = readCookie(DEVICE_COOKIE);
    return device ? { [DEVICE_HEADER]: device } : {};
  },
};

export function apiFetch<S extends z.ZodType | undefined = undefined>(path: string, init?: ApiInit<S>) {
  return request(browser, path, init);
}

/** A JSON response typed by the caller and not parsed: for browser code, which ships without Zod. */
export async function apiJson<T>(path: string, init?: Omit<ApiInit<undefined>, 'schema'>): Promise<T> {
  return (await request(browser, path, init)) as unknown as T;
}
