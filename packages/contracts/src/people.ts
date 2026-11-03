import { z } from 'zod';

/**
 * The only person shape public endpoints return (PRD Q12): first name and last initial, never the
 * full name.
 */
export const PublicPerson = z
  .object({
    id: z.uuid(),
    shortName: z.string().meta({ example: 'Tunde A.' }),
    avatarSeed: z.string(),
  })
  .meta({ id: 'PublicPerson' });
export type PublicPerson = z.infer<typeof PublicPerson>;

/** Adds the full name. Returned only to Plan members, to the activity's host and to the person themselves. */
export const MemberPerson = PublicPerson.extend({
  displayName: z.string().meta({ example: 'Tunde Adeyemi' }),
}).meta({ id: 'MemberPerson' });
export type MemberPerson = z.infer<typeof MemberPerson>;
