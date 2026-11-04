// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_activity_community.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicActivityCommunityCWProxy {
  PublicActivityCommunity slug(String slug);

  PublicActivityCommunity name(String name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicActivityCommunity(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicActivityCommunity(...).copyWith(id: 12, name: "My name")
  /// ```
  PublicActivityCommunity call({String slug, String name});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPublicActivityCommunity.copyWith(...)` or call `instanceOfPublicActivityCommunity.copyWith.fieldName(value)` for a single field.
class _$PublicActivityCommunityCWProxyImpl
    implements _$PublicActivityCommunityCWProxy {
  const _$PublicActivityCommunityCWProxyImpl(this._value);

  final PublicActivityCommunity _value;

  @override
  PublicActivityCommunity slug(String slug) => call(slug: slug);

  @override
  PublicActivityCommunity name(String name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicActivityCommunity(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicActivityCommunity(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PublicActivityCommunity call({
    Object? slug = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return PublicActivityCommunity(
      slug: slug == const $CopyWithPlaceholder() || slug == null
          ? _value.slug
          // ignore: cast_nullable_to_non_nullable
          : slug as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $PublicActivityCommunityCopyWith on PublicActivityCommunity {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPublicActivityCommunity.copyWith(...)` or `instanceOfPublicActivityCommunity.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicActivityCommunityCWProxy get copyWith =>
      _$PublicActivityCommunityCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicActivityCommunity _$PublicActivityCommunityFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PublicActivityCommunity', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['slug', 'name']);
  final val = PublicActivityCommunity(
    slug: $checkedConvert('slug', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$PublicActivityCommunityToJson(
  PublicActivityCommunity instance,
) => <String, dynamic>{'slug': instance.slug, 'name': instance.name};
