import { createHash } from 'node:crypto';
import type { Db } from '../../db/client';

/** The PRD's single flag (Release plan): invite tools, with a stable holdout. */
export const GROUP_INVITES = 'group_invites';

export type Arm = 'exposed' | 'holdout';

/**
 * PRD Holdout design (S8 FR-001): a stable hash of the user ID decides the arm, so it never changes
 * and needs no stored state to enforce.
 */
export function armOf(userId: string, holdoutPercent: number): Arm {
  const bucket = createHash('sha256').update(`${GROUP_INVITES}:${userId}`).digest().readUInt32BE(0) % 100;
  return bucket < holdoutPercent ? 'holdout' : 'exposed';
}

export function createHoldout(db: Db, holdoutPercent: number) {
  return {
    arm: (userId: string) => armOf(userId, holdoutPercent),
    /** The first invite surface a user reaches logs their arm; later ones change nothing (S8 FR-002). */
    async expose(userId: string): Promise<Arm> {
      const arm = armOf(userId, holdoutPercent);
      await db
        .insertInto('exposures')
        .values({ user_id: userId, flag: GROUP_INVITES, arm })
        .onConflict((oc) => oc.columns(['user_id', 'flag']).doNothing())
        .execute();
      return arm;
    },
  };
}

export type Holdout = ReturnType<typeof createHoldout>;
