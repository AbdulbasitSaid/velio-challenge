// One Idempotency-Key per attempt, kept in sessionStorage so a retry or a reload during a slow request
// reuses it and the API never books twice (PRD Edge cases: server error). Cleared after a final outcome.
const keyName = (scope: string) => `velio_${scope}`;

export function attemptKey(scope: string): string {
  try {
    const existing = sessionStorage.getItem(keyName(scope));
    if (existing) return existing;
    const key = crypto.randomUUID();
    sessionStorage.setItem(keyName(scope), key);
    return key;
  } catch {
    return crypto.randomUUID();
  }
}

export function clearAttemptKey(scope: string): void {
  try {
    sessionStorage.removeItem(keyName(scope));
  } catch {
    // Storage blocked: nothing to clear.
  }
}
