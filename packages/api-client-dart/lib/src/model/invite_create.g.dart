// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteCreateCWProxy {
  InviteCreate rail(InviteCreateRailEnum rail);

  InviteCreate inviteeName(String inviteeName);

  InviteCreate contact(String? contact);

  InviteCreate country(String? country);

  InviteCreate note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  InviteCreate call({
    InviteCreateRailEnum rail,
    String inviteeName,
    String? contact,
    String? country,
    String? note,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInviteCreate.copyWith(...)` or call `instanceOfInviteCreate.copyWith.fieldName(value)` for a single field.
class _$InviteCreateCWProxyImpl implements _$InviteCreateCWProxy {
  const _$InviteCreateCWProxyImpl(this._value);

  final InviteCreate _value;

  @override
  InviteCreate rail(InviteCreateRailEnum rail) => call(rail: rail);

  @override
  InviteCreate inviteeName(String inviteeName) =>
      call(inviteeName: inviteeName);

  @override
  InviteCreate contact(String? contact) => call(contact: contact);

  @override
  InviteCreate country(String? country) => call(country: country);

  @override
  InviteCreate note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InviteCreate call({
    Object? rail = const $CopyWithPlaceholder(),
    Object? inviteeName = const $CopyWithPlaceholder(),
    Object? contact = const $CopyWithPlaceholder(),
    Object? country = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return InviteCreate(
      rail: rail == const $CopyWithPlaceholder() || rail == null
          ? _value.rail
          // ignore: cast_nullable_to_non_nullable
          : rail as InviteCreateRailEnum,
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

extension $InviteCreateCopyWith on InviteCreate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInviteCreate.copyWith(...)` or `instanceOfInviteCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteCreateCWProxy get copyWith => _$InviteCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteCreate _$InviteCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('InviteCreate', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['rail', 'inviteeName']);
      final val = InviteCreate(
        rail: $checkedConvert(
          'rail',
          (v) => $enumDecode(_$InviteCreateRailEnumEnumMap, v),
        ),
        inviteeName: $checkedConvert('inviteeName', (v) => v as String),
        contact: $checkedConvert('contact', (v) => v as String?),
        country: $checkedConvert('country', (v) => v as String?),
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$InviteCreateToJson(InviteCreate instance) =>
    <String, dynamic>{
      'rail': _$InviteCreateRailEnumEnumMap[instance.rail]!,
      'inviteeName': instance.inviteeName,
      'contact': ?instance.contact,
      'country': ?instance.country,
      'note': ?instance.note,
    };

const _$InviteCreateRailEnumEnumMap = {InviteCreateRailEnum.public: 'public'};
