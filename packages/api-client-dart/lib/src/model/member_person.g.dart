// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_person.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MemberPersonCWProxy {
  MemberPerson id(String id);

  MemberPerson shortName(String shortName);

  MemberPerson avatarSeed(String avatarSeed);

  MemberPerson displayName(String displayName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MemberPerson(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MemberPerson(...).copyWith(id: 12, name: "My name")
  /// ```
  MemberPerson call({
    String id,
    String shortName,
    String avatarSeed,
    String displayName,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMemberPerson.copyWith(...)` or call `instanceOfMemberPerson.copyWith.fieldName(value)` for a single field.
class _$MemberPersonCWProxyImpl implements _$MemberPersonCWProxy {
  const _$MemberPersonCWProxyImpl(this._value);

  final MemberPerson _value;

  @override
  MemberPerson id(String id) => call(id: id);

  @override
  MemberPerson shortName(String shortName) => call(shortName: shortName);

  @override
  MemberPerson avatarSeed(String avatarSeed) => call(avatarSeed: avatarSeed);

  @override
  MemberPerson displayName(String displayName) =>
      call(displayName: displayName);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MemberPerson(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MemberPerson(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MemberPerson call({
    Object? id = const $CopyWithPlaceholder(),
    Object? shortName = const $CopyWithPlaceholder(),
    Object? avatarSeed = const $CopyWithPlaceholder(),
    Object? displayName = const $CopyWithPlaceholder(),
  }) {
    return MemberPerson(
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
      displayName:
          displayName == const $CopyWithPlaceholder() || displayName == null
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String,
    );
  }
}

extension $MemberPersonCopyWith on MemberPerson {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMemberPerson.copyWith(...)` or `instanceOfMemberPerson.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MemberPersonCWProxy get copyWith => _$MemberPersonCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberPerson _$MemberPersonFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MemberPerson', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['id', 'shortName', 'avatarSeed', 'displayName'],
      );
      final val = MemberPerson(
        id: $checkedConvert('id', (v) => v as String),
        shortName: $checkedConvert('shortName', (v) => v as String),
        avatarSeed: $checkedConvert('avatarSeed', (v) => v as String),
        displayName: $checkedConvert('displayName', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$MemberPersonToJson(MemberPerson instance) =>
    <String, dynamic>{
      'id': instance.id,
      'shortName': instance.shortName,
      'avatarSeed': instance.avatarSeed,
      'displayName': instance.displayName,
    };
