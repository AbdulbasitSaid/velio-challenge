// H2's photo (S7b §4.5, FR-009), as apps/web/lib/photo.ts: centre-cropped to 16:10, encoded at 1280
// and 640 px, and posted straight to the bucket with the API's presigned POSTs, so the API never
// carries the bytes (PRD Q5). JPEG, since the image package can't encode WebP. The bucket gets its
// own Dio: no token, device ID or trace header leaves for S3 (SEC-001).
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:velio_api/velio_api.dart';

import 'api.dart';

const _large = 1280;
const _small = 640;
const _aspect = 16 / 10;

class PhotoError implements Exception {
  const PhotoError(this.unreadable);

  /// The file couldn't be decoded, as opposed to an upload failure.
  final bool unreadable;
}

/// The centre 16:10 part of a w × h image.
({int x, int y, int w, int h}) cropTo16x10(int w, int h) {
  if (w / h > _aspect) {
    final cw = (h * _aspect).round();
    return (x: ((w - cw) / 2).round(), y: 0, w: cw, h: h);
  }
  final ch = (w / _aspect).round();
  return (x: 0, y: ((h - ch) / 2).round(), w: w, h: ch);
}

/// Runs in an isolate: decode, bake the EXIF orientation, crop, and encode both sizes.
({Uint8List large, Uint8List small})? encodePhoto(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final upright = img.bakeOrientation(decoded);
  final c = cropTo16x10(upright.width, upright.height);
  final cropped = img.copyCrop(upright, x: c.x, y: c.y, width: c.w, height: c.h);
  Uint8List at(int width) => img.encodeJpg(
    cropped.width > width ? img.copyResize(cropped, width: width, interpolation: img.Interpolation.average) : cropped,
    quality: 72,
  );
  return (large: at(_large), small: at(_small));
}

class PhotoUploader {
  PhotoUploader(this.api, {Dio? bucket}) : bucket = bucket ?? Dio();
  final Api api;

  /// No interceptors (SEC-001).
  final Dio bucket;

  /// Uploads both sizes and returns the key and the large JPEG for the preview.
  Future<({String key, Uint8List preview})> upload(Uint8List picked) async {
    final encoded = await compute(encodePhoto, picked);
    if (encoded == null) throw const PhotoError(true);
    final PhotoUploadResponse target;
    try {
      target = await api.photoUpload();
    } catch (_) {
      throw const PhotoError(false);
    }
    await Future.wait([_post(target.uploads.large, encoded.large), _post(target.uploads.small, encoded.small)]);
    return (key: target.key!, preview: encoded.large);
  }

  Future<void> _post(PresignedPost target, Uint8List bytes) async {
    try {
      await bucket.post<void>(
        target.url,
        data: FormData.fromMap({
          ...target.fields,
          'file': MultipartFile.fromBytes(bytes, filename: 'photo.jpg', contentType: DioMediaType('image', 'jpeg')),
        }),
      );
    } catch (_) {
      throw const PhotoError(false);
    }
  }
}
