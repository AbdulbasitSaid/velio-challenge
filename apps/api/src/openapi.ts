import { ErrorEnvelope } from '@velio/contracts';

/** Authenticated routes accept the web cookie or a mobile bearer token. */
export const SECURITY: Record<string, string[]>[] = [{ cookieAuth: [] }, { bearerAuth: [] }];

export const errorResponse = (description: string) => ({
  description,
  content: { 'application/json': { schema: ErrorEnvelope } },
});
