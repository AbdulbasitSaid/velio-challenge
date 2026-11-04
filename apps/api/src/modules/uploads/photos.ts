import { randomUUID } from 'node:crypto';
import { HeadObjectCommand, NotFound, S3Client } from '@aws-sdk/client-s3';
import { createPresignedPost } from '@aws-sdk/s3-presigned-post';
import {
  PHOTO_MAX_BYTES,
  type PhotoKey,
  type PhotoUploadRequest,
  type PhotoUploadResponse,
} from '@velio/contracts';
import type { Config } from '../../config';

/** S5 §4.9, FR-013. Long enough to resize, encode and upload on a slow connection. */
const UPLOAD_SECONDS = 10 * 60;

const EXTENSION: Record<PhotoUploadRequest['contentType'], string> = {
  'image/webp': 'webp',
  'image/jpeg': 'jpg',
  'image/avif': 'avif',
};

/** Objects live under `photos/` because CloudFront serves the bucket at `/photos/*` unchanged. */
const objectKey = (key: string) => `photos/${key}`;

/** The 640 px variant's key: `<id>/<uuid>-640.<ext>`. */
export function smallVariantKey(key: string): string {
  return key.replace(/\.([a-z]+)$/, '-640.$1');
}

/**
 * Photos go from the browser straight to S3 through presigned POSTs, so the API never carries the
 * bytes (PRD Q5). The policy pins the key, the type and the size (SEC-006).
 */
export function createPhotoStore(config: Config) {
  const bucket = config.PHOTOS_BUCKET;
  const client = new S3Client({
    region: config.S3_REGION,
    ...(config.S3_ENDPOINT && { endpoint: config.S3_ENDPOINT, forcePathStyle: true }),
    // Unset in production: the default chain picks up the instance role.
    ...(config.S3_ACCESS_KEY_ID &&
      config.S3_SECRET_ACCESS_KEY && {
        credentials: {
          accessKeyId: config.S3_ACCESS_KEY_ID,
          secretAccessKey: config.S3_SECRET_ACCESS_KEY,
        },
      }),
  });

  const presign = (key: string, contentType: string) =>
    createPresignedPost(client, {
      Bucket: bucket,
      Key: objectKey(key),
      Conditions: [['content-length-range', 1, PHOTO_MAX_BYTES]],
      Fields: { 'Content-Type': contentType },
      Expires: UPLOAD_SECONDS,
    });

  return {
    async presignUpload(userId: string, body: PhotoUploadRequest, now: Date): Promise<PhotoUploadResponse> {
      const key = `${userId}/${randomUUID()}.${EXTENSION[body.contentType]}`;
      const [large, small] = await Promise.all([
        presign(key, body.contentType),
        presign(smallVariantKey(key), body.contentType),
      ]);
      return {
        key,
        uploads: { large, small },
        expiresAt: new Date(now.getTime() + UPLOAD_SECONDS * 1000).toISOString(),
      };
    },

    /** True when `key` is the caller's and its object was uploaded (FR-014). */
    async isUploadedBy(key: PhotoKey, userId: string): Promise<boolean> {
      if (!key.startsWith(`${userId}/`)) return false;
      try {
        await client.send(new HeadObjectCommand({ Bucket: bucket, Key: objectKey(key) }));
        return true;
      } catch (err) {
        if (err instanceof NotFound) return false;
        throw err;
      }
    },
  };
}

export type PhotoStore = ReturnType<typeof createPhotoStore>;
