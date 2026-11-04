import { createRoute, OpenAPIHono } from '@hono/zod-openapi';
import { PhotoUploadRequest, PhotoUploadResponse } from '@velio/contracts';
import type { AppEnv } from '../../app';
import { errorResponse, SECURITY } from '../../openapi';
import { requireUser } from '../identity/middleware';
import type { PhotoStore } from './photos';

const photoUploadRoute = createRoute({
  method: 'post',
  path: '/uploads/photos',
  summary: 'Presigned uploads for an activity photo',
  description:
    'Returns two S3 presigned POSTs, for the 1280 px and 640 px variants, each limited to 2 MB of the requested type and valid for 10 minutes. Upload both, then pass `key` as `photoKey` on `POST /activities` or `PATCH /activities/{id}`.',
  security: SECURITY,
  middleware: [requireUser] as const,
  request: {
    body: { required: true, content: { 'application/json': { schema: PhotoUploadRequest } } },
  },
  responses: {
    201: {
      description: 'Upload targets',
      content: { 'application/json': { schema: PhotoUploadResponse } },
    },
    400: errorResponse('`validation_failed`: unsupported type'),
    401: errorResponse('`unauthenticated`'),
  },
});

export function uploadRoutes(photos: PhotoStore, clock: () => Date) {
  const app = new OpenAPIHono<AppEnv>();

  app.openapi(photoUploadRoute, async (c) => {
    const upload = await photos.presignUpload(c.var.user!.id, c.req.valid('json'), clock());
    c.header('cache-control', 'no-store');
    return c.json(upload, 201);
  });

  return app;
}
