import { z } from 'zod';

/** Photo types the upload accepts (S5 §4.9). The web app uploads WebP. */
export const PHOTO_CONTENT_TYPES = ['image/webp', 'image/jpeg', 'image/avif'] as const;

/** Largest photo object, in bytes (S5 FR-013). */
export const PHOTO_MAX_BYTES = 2 * 1024 * 1024;

/**
 * An uploaded photo: `<uploader id>/<uuid>.<ext>`, from `POST /uploads/photos`. Served at
 * `/photos/<key>`, with a 640 px variant at `/photos/<key without ext>-640.<ext>`.
 */
export const PhotoKey = z
  .string()
  .regex(/^[0-9a-f-]{36}\/[0-9a-f-]{36}\.(webp|jpg|avif)$/)
  .meta({ id: 'PhotoKey' });
export type PhotoKey = z.infer<typeof PhotoKey>;

export const PhotoUploadRequest = z
  .object({ contentType: z.enum(PHOTO_CONTENT_TYPES) })
  .meta({ id: 'PhotoUploadRequest' });
export type PhotoUploadRequest = z.infer<typeof PhotoUploadRequest>;

/** An S3 presigned POST: send `fields`, then the file as `file`, as multipart form data to `url`. */
export const PresignedPost = z
  .object({ url: z.string(), fields: z.record(z.string(), z.string()) })
  .meta({ id: 'PresignedPost' });
export type PresignedPost = z.infer<typeof PresignedPost>;

/**
 * Two presigned POSTs, one per variant: `large` (1280 px wide) is the object `key` names, `small`
 * (640 px) its `-640` sibling. Each allows 1 byte to 2 MB of the requested type, until `expiresAt`.
 * Pass `key` as `photoKey` when creating or editing the activity.
 */
export const PhotoUploadResponse = z
  .object({
    key: PhotoKey,
    uploads: z.object({ large: PresignedPost, small: PresignedPost }),
    expiresAt: z.iso.datetime({ offset: true }),
  })
  .meta({ id: 'PhotoUploadResponse' });
export type PhotoUploadResponse = z.infer<typeof PhotoUploadResponse>;
