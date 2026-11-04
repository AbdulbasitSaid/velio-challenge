// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_upload_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PhotoUploadResponseCWProxy {
  PhotoUploadResponse key(String? key);

  PhotoUploadResponse uploads(PhotoUploadResponseUploads uploads);

  PhotoUploadResponse expiresAt(DateTime expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PhotoUploadResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PhotoUploadResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  PhotoUploadResponse call({
    String? key,
    PhotoUploadResponseUploads uploads,
    DateTime expiresAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPhotoUploadResponse.copyWith(...)` or call `instanceOfPhotoUploadResponse.copyWith.fieldName(value)` for a single field.
class _$PhotoUploadResponseCWProxyImpl implements _$PhotoUploadResponseCWProxy {
  const _$PhotoUploadResponseCWProxyImpl(this._value);

  final PhotoUploadResponse _value;

  @override
  PhotoUploadResponse key(String? key) => call(key: key);

  @override
  PhotoUploadResponse uploads(PhotoUploadResponseUploads uploads) =>
      call(uploads: uploads);

  @override
  PhotoUploadResponse expiresAt(DateTime expiresAt) =>
      call(expiresAt: expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PhotoUploadResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PhotoUploadResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PhotoUploadResponse call({
    Object? key = const $CopyWithPlaceholder(),
    Object? uploads = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return PhotoUploadResponse(
      key: key == const $CopyWithPlaceholder()
          ? _value.key
          // ignore: cast_nullable_to_non_nullable
          : key as String?,
      uploads: uploads == const $CopyWithPlaceholder() || uploads == null
          ? _value.uploads
          // ignore: cast_nullable_to_non_nullable
          : uploads as PhotoUploadResponseUploads,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
    );
  }
}

extension $PhotoUploadResponseCopyWith on PhotoUploadResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPhotoUploadResponse.copyWith(...)` or `instanceOfPhotoUploadResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PhotoUploadResponseCWProxy get copyWith =>
      _$PhotoUploadResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhotoUploadResponse _$PhotoUploadResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PhotoUploadResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['key', 'uploads', 'expiresAt']);
      final val = PhotoUploadResponse(
        key: $checkedConvert('key', (v) => v as String?),
        uploads: $checkedConvert(
          'uploads',
          (v) => PhotoUploadResponseUploads.fromJson(v as Map<String, dynamic>),
        ),
        expiresAt: $checkedConvert(
          'expiresAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PhotoUploadResponseToJson(
  PhotoUploadResponse instance,
) => <String, dynamic>{
  'key': instance.key,
  'uploads': instance.uploads.toJson(),
  'expiresAt': instance.expiresAt.toIso8601String(),
};
