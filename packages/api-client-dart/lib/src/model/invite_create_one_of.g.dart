// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_create_one_of.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteCreateOneOfCWProxy {
  InviteCreateOneOf rail(InviteCreateOneOfRailEnum rail);

  InviteCreateOneOf inviteeName(String inviteeName);

  InviteCreateOneOf contact(String? contact);

  InviteCreateOneOf country(String? country);

  InviteCreateOneOf note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteCreateOneOf(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteCreateOneOf(...).copyWith(id: 12, name: "My name")
  /// ```
  InviteCreateOneOf call({
    InviteCreateOneOfRailEnum rail,
    String inviteeName,
    String? contact,
    String? country,
    String? note,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInviteCreateOneOf.copyWith(...)` or call `instanceOfInviteCreateOneOf.copyWith.fieldName(value)` for a single field.
class _$InviteCreateOneOfCWProxyImpl implements _$InviteCreateOneOfCWProxy {
  const _$InviteCreateOneOfCWProxyImpl(this._value);

  final InviteCreateOneOf _value;

  @override
  InviteCreateOneOf rail(InviteCreateOneOfRailEnum rail) => call(rail: rail);

  @override
  InviteCreateOneOf inviteeName(String inviteeName) =>
      call(inviteeName: inviteeName);

  @override
  InviteCreateOneOf contact(String? contact) => call(contact: contact);

  @override
  InviteCreateOneOf country(String? country) => call(country: country);

  @override
  InviteCreateOneOf note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteCreateOneOf(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteCreateOneOf(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InviteCreateOneOf call({
    Object? rail = const $CopyWithPlaceholder(),
    Object? inviteeName = const $CopyWithPlaceholder(),
    Object? contact = const $CopyWithPlaceholder(),
    Object? country = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return InviteCreateOneOf(
      rail: rail == const $CopyWithPlaceholder() || rail == null
          ? _value.rail
          // ignore: cast_nullable_to_non_nullable
          : rail as InviteCreateOneOfRailEnum,
      inviteeName:
          inviteeName == const $CopyWithPlaceholder() || inviteeName == null
          ? _value.inviteeName
          // ignore: cast_nullable_to_non_nullable
          : inviteeName as String,
      contact: contact == const $CopyWithPlaceholder()
          ? _value.contact
          // ignore: cast_nullable_to_non_nullable
          : contact as String?,
      country: country == const $CopyWithPlaceholder()
          ? _value.country
          // ignore: cast_nullable_to_non_nullable
          : country as String?,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $InviteCreateOneOfCopyWith on InviteCreateOneOf {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInviteCreateOneOf.copyWith(...)` or `instanceOfInviteCreateOneOf.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteCreateOneOfCWProxy get copyWith =>
      _$InviteCreateOneOfCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteCreateOneOf _$InviteCreateOneOfFromJson(Map<String, dynamic> json) =>
    $checkedCreate('InviteCreateOneOf', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['rail', 'inviteeName']);
      final val = InviteCreateOneOf(
        rail: $checkedConvert(
          'rail',
          (v) => $enumDecode(_$InviteCreateOneOfRailEnumEnumMap, v),
        ),
        inviteeName: $checkedConvert('inviteeName', (v) => v as String),
        contact: $checkedConvert('contact', (v) => v as String?),
        country: $checkedConvert('country', (v) => v as String?),
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$InviteCreateOneOfToJson(InviteCreateOneOf instance) =>
    <String, dynamic>{
      'rail': _$InviteCreateOneOfRailEnumEnumMap[instance.rail]!,
      'inviteeName': instance.inviteeName,
      'contact': ?instance.contact,
      'country': ?instance.country,
      'note': ?instance.note,
    };

const _$InviteCreateOneOfRailEnumEnumMap = {
  InviteCreateOneOfRailEnum.vouch: 'vouch',
};
