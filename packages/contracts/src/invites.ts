import { z } from 'zod';
import { ActivityState, PublicActivity } from './activities';
import { Booking } from './bookings';
import { MemberPerson, PublicPerson } from './people';

/** 6 characters from an alphabet without look-alikes (PRD I3, R10). */
export const INVITE_CODE_ALPHABET = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

/** Device ID a client generates once and keeps: 1–128 characters from `[A-Za-z0-9_-]`. */
export const DeviceId = z
  .string()
  .regex(/^[A-Za-z0-9_-]{1,128}$/)
  .meta({ example: 'd3b07384-d113-4ec6-a6a3-8a1f2c7b9e10' });

export const InviteCreate = z
  .discriminatedUnion('rail', [
    z.object({
      rail: z.literal('vouch'),
      /** The person the vouch is for; shown in the inviter's Plan. */
      inviteeName: z.string().trim().min(1).max(80),
      /** Used only to match the claim; stored as a keyed hash, never raw. */
      contact: z.string().min(1).max(200).optional(),
      /** ISO 3166 country for phone numbers written without a country code. */
      country: z.string().length(2).optional(),
      /** Shown on the invite page, and to its creator in the Plan; never to the host. */
      note: z.string().trim().max(280).optional(),
    }),
    z.object({ rail: z.literal('public') }),
  ])
  .meta({ id: 'InviteCreate' });
export type InviteCreate = z.infer<typeof InviteCreate>;

export const InviteStatus = z.enum(['created', 'opened', 'claimed', 'expired']).meta({ id: 'InviteStatus' });
export const PauseReason = z.enum(['owner', 'host', 'auto']).meta({ id: 'PauseReason' });

/** An invite as its creator sees it. */
export const Invite = z
  .object({
    id: z.uuid(),
    code: z.string().meta({ example: 'K7M2QX' }),
    link: z.string().meta({ example: 'https://d1234.cloudfront.net/i/K7M2QX' }),
    rail: z.enum(['vouch', 'public']),
    inviteeName: z.string().nullable(),
    note: z.string().nullable(),
    status: InviteStatus,
    opens: z.number().int(),
    claims: z.number().int(),
    paused: z.boolean(),
    pausedReason: PauseReason.nullable(),
    createdBy: MemberPerson,
    createdAt: z.iso.datetime({ offset: true }),
  })
  .meta({ id: 'Invite' });
export type Invite = z.infer<typeof Invite>;

/** The public invite page's data. The invitee's name and contact are never included. */
export const InviteView = z
  .object({
    code: z.string(),
    rail: z.enum(['vouch', 'public']),
    /** Sold out isn't an invite status: `activity.status` shows it, live. */
    status: z.enum(['claimable', 'claimed', 'expired', 'paused']),
    pausedReason: PauseReason.nullable(),
    inviter: PublicPerson,
    /** Vouch only. */
    note: z.string().nullable(),
    /** The signed-in caller claimed this vouch. */
    claimedByViewer: z.boolean(),
    activity: PublicActivity,
  })
  .meta({ id: 'InviteView' });
export type InviteView = z.infer<typeof InviteView>;

export const OpenCreate = z
  .object({ platform: z.enum(['web', 'ios', 'android']).optional() })
  .meta({ id: 'OpenCreate' });

/** Identity for a caller without a session; ignored when a session is sent. */
export const ClaimCreate = z
  .object({
    displayName: z.string().trim().min(1).max(80).optional(),
    contact: z.string().min(1).max(200).optional(),
    country: z.string().length(2).optional(),
    platform: z.enum(['web', 'ios', 'android']).optional(),
  })
  .meta({ id: 'ClaimCreate' });
export type ClaimCreate = z.infer<typeof ClaimCreate>;

export const ClaimResponse = z
  .object({
    booking: Booking,
    activity: ActivityState,
    planId: z.uuid(),
    user: MemberPerson,
    /** Only for `X-Client: mobile` callers that had no session; web callers get the cookie. */
    token: z.string().optional(),
  })
  .meta({ id: 'ClaimResponse' });
export type ClaimResponse = z.infer<typeof ClaimResponse>;
