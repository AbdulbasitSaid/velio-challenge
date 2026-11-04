// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProfileCWProxy {
  Profile person(PublicPerson person);

  Profile memberSince(String memberSince);

  Profile hosting(List<ActivityCard> hosting);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Profile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Profile(...).copyWith(id: 12, name: "My name")
  /// ```
  Profile call({
    PublicPerson person,
    String memberSince,
    List<ActivityCard> hosting,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProfile.copyWith(...)` or call `instanceOfProfile.copyWith.fieldName(value)` for a single field.
class _$ProfileCWProxyImpl implements _$ProfileCWProxy {
  const _$ProfileCWProxyImpl(this._value);

  final Profile _value;

  @override
  Profile person(PublicPerson person) => call(person: person);

  @override
  Profile memberSince(String memberSince) => call(memberSince: memberSince);

  @override
  Profile hosting(List<ActivityCard> hosting) => call(hosting: hosting);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Profile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Profile(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Profile call({
    Object? person = const $CopyWithPlaceholder(),
    Object? memberSince = const $CopyWithPlaceholder(),
    Object? hosting = const $CopyWithPlaceholder(),
  }) {
    return Profile(
      person: person == const $CopyWithPlaceholder() || person == null
          ? _value.person
          // ignore: cast_nullable_to_non_nullable
          : person as PublicPerson,
      memberSince:
          memberSince == const $CopyWithPlaceholder() || memberSince == null
          ? _value.memberSince
          // ignore: cast_nullable_to_non_nullable
          : memberSince as String,
      hosting: hosting == const $CopyWithPlaceholder() || hosting == null
          ? _value.hosting
          // ignore: cast_nullable_to_non_nullable
          : hosting as List<ActivityCard>,
    );
  }
}

extension $ProfileCopyWith on Profile {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProfile.copyWith(...)` or `instanceOfProfile.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProfileCWProxy get copyWith => _$ProfileCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Profile _$ProfileFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Profile',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['person', 'memberSince', 'hosting']);
    final val = Profile(
      person: $checkedConvert(
        'person',
        (v) => PublicPerson.fromJson(v as Map<String, dynamic>),
      ),
      memberSince: $checkedConvert('memberSince', (v) => v as String),
      hosting: $checkedConvert(
        'hosting',
        (v) => (v as List<dynamic>)
            .map((e) => ActivityCard.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
    );
    return val;
  },
);

Map<String, dynamic> _$ProfileToJson(Profile instance) => <String, dynamic>{
  'person': instance.person.toJson(),
  'memberSince': instance.memberSince,
  'hosting': instance.hosting.map((e) => e.toJson()).toList(),
};
