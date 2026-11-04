// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SessionCreateCWProxy {
  SessionCreate displayName(String displayName);

  SessionCreate contact(String contact);

  SessionCreate country(String? country);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SessionCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SessionCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  SessionCreate call({String displayName, String contact, String? country});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSessionCreate.copyWith(...)` or call `instanceOfSessionCreate.copyWith.fieldName(value)` for a single field.
class _$SessionCreateCWProxyImpl implements _$SessionCreateCWProxy {
  const _$SessionCreateCWProxyImpl(this._value);

  final SessionCreate _value;

  @override
  SessionCreate displayName(String displayName) =>
      call(displayName: displayName);

  @override
  SessionCreate contact(String contact) => call(contact: contact);

  @override
  SessionCreate country(String? country) => call(country: country);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SessionCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SessionCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SessionCreate call({
    Object? displayName = const $CopyWithPlaceholder(),
    Object? contact = const $CopyWithPlaceholder(),
    Object? country = const $CopyWithPlaceholder(),
  }) {
    return SessionCreate(
      displayName:
          displayName == const $CopyWithPlaceholder() || displayName == null
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String,
      contact: contact == const $CopyWithPlaceholder() || contact == null
          ? _value.contact
          // ignore: cast_nullable_to_non_nullable
          : contact as String,
      country: country == const $CopyWithPlaceholder()
          ? _value.country
          // ignore: cast_nullable_to_non_nullable
          : country as String?,
    );
  }
}

extension $SessionCreateCopyWith on SessionCreate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSessionCreate.copyWith(...)` or `instanceOfSessionCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SessionCreateCWProxy get copyWith => _$SessionCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionCreate _$SessionCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SessionCreate', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['displayName', 'contact']);
      final val = SessionCreate(
        displayName: $checkedConvert('displayName', (v) => v as String),
        contact: $checkedConvert('contact', (v) => v as String),
        country: $checkedConvert('country', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SessionCreateToJson(SessionCreate instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'contact': instance.contact,
      'country': ?instance.country,
    };
