// H2's photo (S5 §4.9, FR-013): the browser resizes and encodes it, then posts both variants straight to
// the bucket with the API's presigned POSTs, so the API never carries the bytes (PRD Q5).
import type { PhotoUploadResponse, PresignedPost } from '@velio/contracts';
import { apiJson } from './api/client';

const LARGE = 1280;
const SMALL = 640;

export class PhotoError extends Error {
  constructor(readonly reason: 'unreadable' | 'upload') {
    super(reason);
    this.name = 'PhotoError';
  }
}

function toBlob(canvas: HTMLCanvasElement, type: string, quality: number): Promise<Blob | null> {
  return new Promise((resolve) => canvas.toBlob(resolve, type, quality));
}

/** WebP where the browser can encode it; JPEG otherwise (Safari's canvas has no WebP encoder). */
async function encode(bitmap: ImageBitmap, width: number, type?: string): Promise<Blob> {
  const scale = Math.min(1, width / bitmap.width);
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(bitmap.width * scale);
  canvas.height = Math.round(bitmap.height * scale);
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new PhotoError('unreadable');
  ctx.drawImage(bitmap, 0, 0, canvas.width, canvas.height);
  if (type !== 'image/jpeg') {
    const webp = await toBlob(canvas, 'image/webp', 0.8);
    if (webp?.type === 'image/webp') return webp;
  }
  const jpeg = await toBlob(canvas, 'image/jpeg', 0.82);
  if (!jpeg) throw new PhotoError('unreadable');
  return jpeg;
}

async function post(target: PresignedPost, blob: Blob): Promise<void> {
  const form = new FormData();
  for (const [k, v] of Object.entries(target.fields)) form.append(k, v);
  form.append('file', blob);
  let res: Response;
  try {
    res = await fetch(target.url, { method: 'POST', body: form });
  } catch {
    throw new PhotoError('upload');
  }
  if (!res.ok) throw new PhotoError('upload');
}

/** Uploads `file` as 1280 px and 640 px variants of one type. Returns the key and a local preview. */
export async function uploadPhoto(file: File): Promise<{ key: string; previewUrl: string }> {
  let large: Blob;
  let small: Blob;
  try {
    const bitmap = await createImageBitmap(file, { imageOrientation: 'from-image' });
    large = await encode(bitmap, LARGE);
    small = await encode(bitmap, SMALL, large.type);
    bitmap.close();
  } catch (err) {
    if (err instanceof PhotoError) throw err;
    throw new PhotoError('unreadable');
  }
  let upload: PhotoUploadResponse;
  try {
    upload = await apiJson<PhotoUploadResponse>('/uploads/photos', {
      method: 'POST',
      body: { contentType: large.type },
    });
  } catch {
    throw new PhotoError('upload');
  }
  await Promise.all([post(upload.uploads.large, large), post(upload.uploads.small, small)]);
  return { key: upload.key, previewUrl: URL.createObjectURL(large) };
}
