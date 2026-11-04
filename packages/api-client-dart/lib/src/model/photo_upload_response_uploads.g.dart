// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_upload_response_uploads.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PhotoUploadResponseUploadsCWProxy {
  PhotoUploadResponseUploads large(PresignedPost large);

  PhotoUploadResponseUploads small(PresignedPost small);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PhotoUploadResponseUploads(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PhotoUploadResponseUploads(...).copyWith(id: 12, name: "My name")
  /// ```
  PhotoUploadResponseUploads call({PresignedPost large, PresignedPost small});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPhotoUploadResponseUploads.copyWith(...)` or call `instanceOfPhotoUploadResponseUploads.copyWith.fieldName(value)` for a single field.
class _$PhotoUploadResponseUploadsCWProxyImpl
    implements _$PhotoUploadResponseUploadsCWProxy {
  const _$PhotoUploadResponseUploadsCWProxyImpl(this._value);

  final PhotoUploadResponseUploads _value;

  @override
  PhotoUploadResponseUploads large(PresignedPost large) => call(large: large);

  @override
  PhotoUploadResponseUploads small(PresignedPost small) => call(small: small);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PhotoUploadResponseUploads(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PhotoUploadResponseUploads(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PhotoUploadResponseUploads call({
    Object? large = const $CopyWithPlaceholder(),
    Object? small = const $CopyWithPlaceholder(),
  }) {
    return PhotoUploadResponseUploads(
      large: large == const $CopyWithPlaceholder() || large == null
          ? _value.large
          // ignore: cast_nullable_to_non_nullable
          : large as PresignedPost,
      small: small == const $CopyWithPlaceholder() || small == null
          ? _value.small
          // ignore: cast_nullable_to_non_nullable
          : small as PresignedPost,
    );
  }
}

extension $PhotoUploadResponseUploadsCopyWith on PhotoUploadResponseUploads {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPhotoUploadResponseUploads.copyWith(...)` or `instanceOfPhotoUploadResponseUploads.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PhotoUploadResponseUploadsCWProxy get copyWith =>
      _$PhotoUploadResponseUploadsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhotoUploadResponseUploads _$PhotoUploadResponseUploadsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PhotoUploadResponseUploads', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['large', 'small']);
  final val = PhotoUploadResponseUploads(
    large: $checkedConvert(
      'large',
      (v) => PresignedPost.fromJson(v as Map<String, dynamic>),
    ),
    small: $checkedConvert(
      'small',
      (v) => PresignedPost.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$PhotoUploadResponseUploadsToJson(
  PhotoUploadResponseUploads instance,
) => <String, dynamic>{
  'large': instance.large.toJson(),
  'small': instance.small.toJson(),
};
