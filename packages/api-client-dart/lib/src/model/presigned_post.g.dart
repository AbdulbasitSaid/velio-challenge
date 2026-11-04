// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presigned_post.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PresignedPostCWProxy {
  PresignedPost url(String url);

  PresignedPost fields(Map<String, String> fields);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PresignedPost(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PresignedPost(...).copyWith(id: 12, name: "My name")
  /// ```
  PresignedPost call({String url, Map<String, String> fields});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPresignedPost.copyWith(...)` or call `instanceOfPresignedPost.copyWith.fieldName(value)` for a single field.
class _$PresignedPostCWProxyImpl implements _$PresignedPostCWProxy {
  const _$PresignedPostCWProxyImpl(this._value);

  final PresignedPost _value;

  @override
  PresignedPost url(String url) => call(url: url);

  @override
  PresignedPost fields(Map<String, String> fields) => call(fields: fields);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PresignedPost(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PresignedPost(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PresignedPost call({
    Object? url = const $CopyWithPlaceholder(),
    Object? fields = const $CopyWithPlaceholder(),
  }) {
    return PresignedPost(
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      fields: fields == const $CopyWithPlaceholder() || fields == null
          ? _value.fields
          // ignore: cast_nullable_to_non_nullable
          : fields as Map<String, String>,
    );
  }
}

extension $PresignedPostCopyWith on PresignedPost {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPresignedPost.copyWith(...)` or `instanceOfPresignedPost.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PresignedPostCWProxy get copyWith => _$PresignedPostCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresignedPost _$PresignedPostFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PresignedPost', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['url', 'fields']);
      final val = PresignedPost(
        url: $checkedConvert('url', (v) => v as String),
        fields: $checkedConvert(
          'fields',
          (v) => Map<String, String>.from(v as Map),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PresignedPostToJson(PresignedPost instance) =>
    <String, dynamic>{'url': instance.url, 'fields': instance.fields};
