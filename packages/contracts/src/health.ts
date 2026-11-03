import { z } from 'zod';

export const Health = z
  .object({
    status: z.enum(['ok', 'unavailable']),
  })
  .meta({ id: 'Health' });
export type Health = z.infer<typeof Health>;
