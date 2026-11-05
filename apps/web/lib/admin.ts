// Admin page helpers (S8 FR-014): formatting and status for the PRD goal tiles. Pure, for tests.
import type { AdminGoal, Ratio } from '@velio/contracts';

/** Kept for the tab only (sessionStorage), sent as a header, never in a URL (S8 SEC-001). */
export const ADMIN_TOKEN_KEY = 'velio_admin_token';

const pct = (v: number) => `${(v * 100).toFixed(v >= 0.995 && v < 1 ? 1 : 0)}%`;

export function formatValue(value: number | null, unit: AdminGoal['unit']): string {
  if (value === null) return '—';
  if (unit === 'ratio') return pct(value);
  if (unit === 'seconds') return `${value.toFixed(2)} s`;
  return value.toLocaleString('en-GB');
}

export function formatRatio(r: Ratio): string {
  return r.value === null ? '—' : pct(r.value);
}

export function formatTarget(goal: AdminGoal): string {
  if (goal.target === null) return 'Target set after the week-1 baseline';
  if (goal.id === 'no_oversell') return 'Target: 0';
  if (goal.unit === 'seconds') return `Target: p95 ≤ ${goal.target} s`;
  return `Target: ≥ ${pct(goal.target)}`;
}

export type GoalStatus = 'triggered' | 'ok' | 'no-data' | 'baseline';

export function goalStatus(goal: AdminGoal): GoalStatus {
  if (goal.triggered) return 'triggered';
  if (goal.value === null || goal.sample === 0) return 'no-data';
  if (goal.target === null) return 'baseline';
  return 'ok';
}
