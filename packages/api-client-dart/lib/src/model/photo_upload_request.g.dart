// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_upload_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PhotoUploadRequestCWProxy {
  PhotoUploadRequest contentType(PhotoUploadRequestContentTypeEnum contentType);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PhotoUploadRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PhotoUploadRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  PhotoUploadRequest call({PhotoUploadRequestContentTypeEnum contentType});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPhotoUploadRequest.copyWith(...)` or call `instanceOfPhotoUploadRequest.copyWith.fieldName(value)` for a single field.
class _$PhotoUploadRequestCWProxyImpl implements _$PhotoUploadRequestCWProxy {
  const _$PhotoUploadRequestCWProxyImpl(this._value);

  final PhotoUploadRequest _value;

  @override
  PhotoUploadRequest contentType(
    PhotoUploadRequestContentTypeEnum contentType,
  ) => call(contentType: contentType);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PhotoUploadRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PhotoUploadRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PhotoUploadRequest call({
    Object? contentType = const $CopyWithPlaceholder(),
  }) {
    return PhotoUploadRequest(
      contentType:
          contentType == const $CopyWithPlaceholder() || contentType == null
          ? _value.contentType
          // ignore: cast_nullable_to_non_nullable
          : contentType as PhotoUploadRequestContentTypeEnum,
    );
  }
}

extension $PhotoUploadRequestCopyWith on PhotoUploadRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPhotoUploadRequest.copyWith(...)` or `instanceOfPhotoUploadRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PhotoUploadRequestCWProxy get copyWith =>
      _$PhotoUploadRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhotoUploadRequest _$PhotoUploadRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PhotoUploadRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['contentType']);
      final val = PhotoUploadRequest(
        contentType: $checkedConvert(
          'contentType',
          (v) => $enumDecode(_$PhotoUploadRequestContentTypeEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PhotoUploadRequestToJson(PhotoUploadRequest instance) =>
    <String, dynamic>{
      'contentType':
          _$PhotoUploadRequestContentTypeEnumEnumMap[instance.contentType]!,
    };

const _$PhotoUploadRequestContentTypeEnumEnumMap = {
  PhotoUploadRequestContentTypeEnum.imageSlashWebp: 'image/webp',
  PhotoUploadRequestContentTypeEnum.imageSlashJpeg: 'image/jpeg',
  PhotoUploadRequestContentTypeEnum.imageSlashAvif: 'image/avif',
};
