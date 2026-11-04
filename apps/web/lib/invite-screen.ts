// S6 §4.3: which screen an invite shows. Pure, so every row is unit-tested (V-STATE-1) and the live
// island can re-run it when spots change (sold out isn't an invite state: PRD Lifecycles).
import type { InviteView } from '@velio/contracts';

export type InviteScreen =
  | { kind: 'claimed-own' } // G7 own
  | { kind: 'claimed-other' } // G7 other
  | { kind: 'expired' } // G6
  | { kind: 'paused' } // paused public link (S6 §12 Q2)
  | { kind: 'sold-out' } // G5
  | { kind: 'open'; block: null | 'host' | 'already-going' | 'bookings-paused' }; // G1 (vouch) / G2 (public)

export function selectScreen(view: InviteView, spotsLeft = view.activity.spotsLeft): InviteScreen {
  if (view.status === 'claimed') return { kind: view.claimedByViewer ? 'claimed-own' : 'claimed-other' };
  if (view.status === 'expired' || view.activity.status === 'started') return { kind: 'expired' };
  if (view.status === 'paused') return { kind: 'paused' };
  const viewer = view.activity.viewer;
  if (viewer?.isHost) return { kind: 'open', block: 'host' };
  if (viewer?.booking?.status === 'confirmed') return { kind: 'open', block: 'already-going' };
  if (spotsLeft <= 0) return { kind: 'sold-out' };
  if (view.activity.bookingsPaused) return { kind: 'open', block: 'bookings-paused' };
  return { kind: 'open', block: null };
}
