/** How long a published version can still be acknowledged (S3 PLANNING §4.8). */
export const ACK_WINDOW_MS = 60_000;

/**
 * Recent `(activityId, version) → committedAt`, per process. Only versions this instance published
 * are acknowledged, so a client can't report latency for an event it never received.
 */
export function createAckWindow(now: () => number = Date.now, windowMs = ACK_WINDOW_MS) {
  // Insertion order is publish order, so expired entries are always at the front.
  const published = new Map<string, { committedAt: number; at: number }>();

  function prune() {
    const cutoff = now() - windowMs;
    for (const [key, entry] of published) {
      if (entry.at > cutoff) break;
      published.delete(key);
    }
  }

  return {
    record(activityId: string, version: number, committedAt: number) {
      prune();
      published.set(`${activityId}:${version}`, { committedAt, at: now() });
    },
    /** The commit time of a version still in the window, or undefined. */
    committedAt(activityId: string, version: number): number | undefined {
      prune();
      return published.get(`${activityId}:${version}`)?.committedAt;
    },
  };
}

export type AckWindow = ReturnType<typeof createAckWindow>;
