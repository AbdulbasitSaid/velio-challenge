import { z } from 'zod';
import { ActivityCard } from './activities';
import { PublicPerson } from './people';

export const Community = z
  .object({
    slug: z.string(),
    name: z.string(),
    blurb: z.string(),
    coverPhotoUrl: z.string().nullable(),
    upcomingCount: z.number().int(),
  })
  .meta({ id: 'Community' });

export const CommunityList = z.object({ communities: z.array(Community) }).meta({ id: 'CommunityList' });

export const CommunityPage = z
  .object({ community: Community, activities: z.array(ActivityCard) })
  .meta({ id: 'CommunityPage' });

/** PRD Q10: never bookings or Plans. */
export const Profile = z
  .object({
    person: PublicPerson,
    /** `YYYY-MM`, for "On Velio since". */
    memberSince: z.string().meta({ example: '2026-11' }),
    hosting: z.array(ActivityCard),
  })
  .meta({ id: 'Profile' });

/** PRD Q9: what sold-out and expired screens offer instead of a dead end. */
export const NextSteps = z
  .object({ hostOtherDates: z.array(ActivityCard), moreInCommunity: z.array(ActivityCard) })
  .meta({ id: 'NextSteps' });
