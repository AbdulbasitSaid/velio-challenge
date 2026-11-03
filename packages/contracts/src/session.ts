import { z } from 'zod';
import { MemberPerson } from './people';

export const SessionCreate = z
  .object({
    displayName: z.string().trim().min(1).max(100),
    /** An email address or a phone number. */
    contact: z.string().trim().min(1).max(254),
    /** ISO 3166-1 alpha-2 country used to read a phone number written without its country code. */
    country: z
      .string()
      .regex(/^[A-Z]{2}$/)
      .optional(),
  })
  .meta({ id: 'SessionCreate' });
export type SessionCreate = z.infer<typeof SessionCreate>;

export const SessionResponse = z
  .object({
    user: MemberPerson,
    /** Present only for clients that send `X-Client: mobile`; web clients get an httpOnly cookie. */
    token: z.string().optional(),
  })
  .meta({ id: 'SessionResponse' });
export type SessionResponse = z.infer<typeof SessionResponse>;
