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

/** Every screen shows photos at 16:10 or wider, cover-cropped from the centre (S6 D4). */
const ASPECT = 16 / 10;

/** The centre 16:10 part of a w × h image. Exported for tests. */
export function cropTo16x10(w: number, h: number): { sx: number; sy: number; sw: number; sh: number } {
  if (w / h > ASPECT) {
    const sw = Math.round(h * ASPECT);
    return { sx: Math.round((w - sw) / 2), sy: 0, sw, sh: h };
  }
  const sh = Math.round(w / ASPECT);
  return { sx: 0, sy: Math.round((h - sh) / 2), sw: w, sh };
}

/**
 * Cropped to 16:10, then WebP where the browser can encode it; JPEG otherwise (Safari's canvas has no
 * WebP encoder). Quality 0.7 keeps a real 640 px photo near 45 kB, inside the invite hero budget
 * (S6 NFR, D4).
 */
async function encode(bitmap: ImageBitmap, width: number, type?: string): Promise<Blob> {
  const crop = cropTo16x10(bitmap.width, bitmap.height);
  const scale = Math.min(1, width / crop.sw);
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(crop.sw * scale);
  canvas.height = Math.round(crop.sh * scale);
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new PhotoError('unreadable');
  ctx.drawImage(bitmap, crop.sx, crop.sy, crop.sw, crop.sh, 0, 0, canvas.width, canvas.height);
  if (type !== 'image/jpeg') {
    const webp = await toBlob(canvas, 'image/webp', 0.7);
    if (webp?.type === 'image/webp') return webp;
  }
  const jpeg = await toBlob(canvas, 'image/jpeg', 0.72);
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
