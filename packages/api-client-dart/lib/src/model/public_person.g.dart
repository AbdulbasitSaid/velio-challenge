// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_person.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicPersonCWProxy {
  PublicPerson id(String id);

  PublicPerson shortName(String shortName);

  PublicPerson avatarSeed(String avatarSeed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicPerson(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicPerson(...).copyWith(id: 12, name: "My name")
  /// ```
  PublicPerson call({String id, String shortName, String avatarSeed});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPublicPerson.copyWith(...)` or call `instanceOfPublicPerson.copyWith.fieldName(value)` for a single field.
class _$PublicPersonCWProxyImpl implements _$PublicPersonCWProxy {
  const _$PublicPersonCWProxyImpl(this._value);

  final PublicPerson _value;

  @override
  PublicPerson id(String id) => call(id: id);

  @override
  PublicPerson shortName(String shortName) => call(shortName: shortName);

  @override
  PublicPerson avatarSeed(String avatarSeed) => call(avatarSeed: avatarSeed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicPerson(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicPerson(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PublicPerson call({
    Object? id = const $CopyWithPlaceholder(),
    Object? shortName = const $CopyWithPlaceholder(),
    Object? avatarSeed = const $CopyWithPlaceholder(),
  }) {
    return PublicPerson(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      shortName: shortName == const $CopyWithPlaceholder() || shortName == null
          ? _value.shortName
          // ignore: cast_nullable_to_non_nullable
          : shortName as String,
      avatarSeed:
          avatarSeed == const $CopyWithPlaceholder() || avatarSeed == null
          ? _value.avatarSeed
          // ignore: cast_nullable_to_non_nullable
          : avatarSeed as String,
    );
  }
}

extension $PublicPersonCopyWith on PublicPerson {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPublicPerson.copyWith(...)` or `instanceOfPublicPerson.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicPersonCWProxy get copyWith => _$PublicPersonCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicPerson _$PublicPersonFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublicPerson', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'shortName', 'avatarSeed']);
      final val = PublicPerson(
        id: $checkedConvert('id', (v) => v as String),
        shortName: $checkedConvert('shortName', (v) => v as String),
        avatarSeed: $checkedConvert('avatarSeed', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PublicPersonToJson(PublicPerson instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shortName': instance.shortName,
      'avatarSeed': instance.avatarSeed,
    };
