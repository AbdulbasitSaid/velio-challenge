/**
 * Recent samples in a fixed ring, for figures the admin page shows without a metrics backend
 * (S8 FR-009: realtime p95). Per process; Grafana is the fleet-wide view.
 */
export function createRollingWindow(windowMs = 3_600_000, capacity = 10_000, now: () => number = Date.now) {
  const values = new Float64Array(capacity);
  const times = new Float64Array(capacity);
  let next = 0;
  let size = 0;

  function recent(): number[] {
    const cutoff = now() - windowMs;
    const out: number[] = [];
    for (let i = 0; i < size; i++) if (times[i]! >= cutoff) out.push(values[i]!);
    return out;
  }

  return {
    windowMs,
    record(value: number) {
      values[next] = value;
      times[next] = now();
      next = (next + 1) % capacity;
      size = Math.min(size + 1, capacity);
    },
    /** Nearest-rank quantile of the samples in the window, or null without any. */
    quantile(q: number): { value: number | null; count: number } {
      const sorted = recent().sort((a, b) => a - b);
      if (sorted.length === 0) return { value: null, count: 0 };
      return {
        value: sorted[Math.min(sorted.length - 1, Math.ceil(q * sorted.length) - 1)]!,
        count: sorted.length,
      };
    },
  };
}

export type RollingWindow = ReturnType<typeof createRollingWindow>;
