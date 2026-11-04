// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClaimCreateCWProxy {
  ClaimCreate displayName(String? displayName);

  ClaimCreate contact(String? contact);

  ClaimCreate country(String? country);

  ClaimCreate platform(ClaimCreatePlatformEnum? platform);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ClaimCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ClaimCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  ClaimCreate call({
    String? displayName,
    String? contact,
    String? country,
    ClaimCreatePlatformEnum? platform,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfClaimCreate.copyWith(...)` or call `instanceOfClaimCreate.copyWith.fieldName(value)` for a single field.
class _$ClaimCreateCWProxyImpl implements _$ClaimCreateCWProxy {
  const _$ClaimCreateCWProxyImpl(this._value);

  final ClaimCreate _value;

  @override
  ClaimCreate displayName(String? displayName) =>
      call(displayName: displayName);

  @override
  ClaimCreate contact(String? contact) => call(contact: contact);

  @override
  ClaimCreate country(String? country) => call(country: country);

  @override
  ClaimCreate platform(ClaimCreatePlatformEnum? platform) =>
      call(platform: platform);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ClaimCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ClaimCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ClaimCreate call({
    Object? displayName = const $CopyWithPlaceholder(),
    Object? contact = const $CopyWithPlaceholder(),
    Object? country = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
  }) {
    return ClaimCreate(
      displayName: displayName == const $CopyWithPlaceholder()
          ? _value.displayName
          // ignore: cast_nullable_to_non_nullable
          : displayName as String?,
      contact: contact == const $CopyWithPlaceholder()
          ? _value.contact
          // ignore: cast_nullable_to_non_nullable
          : contact as String?,
      country: country == const $CopyWithPlaceholder()
          ? _value.country
          // ignore: cast_nullable_to_non_nullable
          : country as String?,
      platform: platform == const $CopyWithPlaceholder()
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as ClaimCreatePlatformEnum?,
    );
  }
}

extension $ClaimCreateCopyWith on ClaimCreate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfClaimCreate.copyWith(...)` or `instanceOfClaimCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ClaimCreateCWProxy get copyWith => _$ClaimCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClaimCreate _$ClaimCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ClaimCreate', json, ($checkedConvert) {
      final val = ClaimCreate(
        displayName: $checkedConvert('displayName', (v) => v as String?),
        contact: $checkedConvert('contact', (v) => v as String?),
        country: $checkedConvert('country', (v) => v as String?),
        platform: $checkedConvert(
          'platform',
          (v) => $enumDecodeNullable(_$ClaimCreatePlatformEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ClaimCreateToJson(ClaimCreate instance) =>
    <String, dynamic>{
      'displayName': ?instance.displayName,
      'contact': ?instance.contact,
      'country': ?instance.country,
      'platform': ?_$ClaimCreatePlatformEnumEnumMap[instance.platform],
    };

const _$ClaimCreatePlatformEnumEnumMap = {
  ClaimCreatePlatformEnum.web: 'web',
  ClaimCreatePlatformEnum.ios: 'ios',
  ClaimCreatePlatformEnum.android: 'android',
};
