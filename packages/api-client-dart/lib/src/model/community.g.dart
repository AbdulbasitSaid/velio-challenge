// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CommunityCWProxy {
  Community slug(String slug);

  Community name(String name);

  Community blurb(String blurb);

  Community coverPhotoUrl(String? coverPhotoUrl);

  Community upcomingCount(int upcomingCount);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Community(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Community(...).copyWith(id: 12, name: "My name")
  /// ```
  Community call({
    String slug,
    String name,
    String blurb,
    String? coverPhotoUrl,
    int upcomingCount,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCommunity.copyWith(...)` or call `instanceOfCommunity.copyWith.fieldName(value)` for a single field.
class _$CommunityCWProxyImpl implements _$CommunityCWProxy {
  const _$CommunityCWProxyImpl(this._value);

  final Community _value;

  @override
  Community slug(String slug) => call(slug: slug);

  @override
  Community name(String name) => call(name: name);

  @override
  Community blurb(String blurb) => call(blurb: blurb);

  @override
  Community coverPhotoUrl(String? coverPhotoUrl) =>
      call(coverPhotoUrl: coverPhotoUrl);

  @override
  Community upcomingCount(int upcomingCount) =>
      call(upcomingCount: upcomingCount);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Community(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Community(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Community call({
    Object? slug = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? blurb = const $CopyWithPlaceholder(),
    Object? coverPhotoUrl = const $CopyWithPlaceholder(),
    Object? upcomingCount = const $CopyWithPlaceholder(),
  }) {
    return Community(
      slug: slug == const $CopyWithPlaceholder() || slug == null
          ? _value.slug
          // ignore: cast_nullable_to_non_nullable
          : slug as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      blurb: blurb == const $CopyWithPlaceholder() || blurb == null
          ? _value.blurb
          // ignore: cast_nullable_to_non_nullable
          : blurb as String,
      coverPhotoUrl: coverPhotoUrl == const $CopyWithPlaceholder()
          ? _value.coverPhotoUrl
          // ignore: cast_nullable_to_non_nullable
          : coverPhotoUrl as String?,
      upcomingCount:
          upcomingCount == const $CopyWithPlaceholder() || upcomingCount == null
          ? _value.upcomingCount
          // ignore: cast_nullable_to_non_nullable
          : upcomingCount as int,
    );
  }
}

extension $CommunityCopyWith on Community {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCommunity.copyWith(...)` or `instanceOfCommunity.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CommunityCWProxy get copyWith => _$CommunityCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Community _$CommunityFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Community', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'slug',
          'name',
          'blurb',
          'coverPhotoUrl',
          'upcomingCount',
        ],
      );
      final val = Community(
        slug: $checkedConvert('slug', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        blurb: $checkedConvert('blurb', (v) => v as String),
        coverPhotoUrl: $checkedConvert('coverPhotoUrl', (v) => v as String?),
        upcomingCount: $checkedConvert(
          'upcomingCount',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CommunityToJson(Community instance) => <String, dynamic>{
  'slug': instance.slug,
  'name': instance.name,
  'blurb': instance.blurb,
  'coverPhotoUrl': instance.coverPhotoUrl,
  'upcomingCount': instance.upcomingCount,
};
