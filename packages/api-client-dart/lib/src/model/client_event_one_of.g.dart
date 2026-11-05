// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_event_one_of.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClientEventOneOfCWProxy {
  ClientEventOneOf name(ClientEventOneOfNameEnum name);

  ClientEventOneOf activityId(String activityId);

  ClientEventOneOf platform(ClientEventOneOfPlatformEnum? platform);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ClientEventOneOf(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ClientEventOneOf(...).copyWith(id: 12, name: "My name")
  /// ```
  ClientEventOneOf call({
    ClientEventOneOfNameEnum name,
    String activityId,
    ClientEventOneOfPlatformEnum? platform,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfClientEventOneOf.copyWith(...)` or call `instanceOfClientEventOneOf.copyWith.fieldName(value)` for a single field.
class _$ClientEventOneOfCWProxyImpl implements _$ClientEventOneOfCWProxy {
  const _$ClientEventOneOfCWProxyImpl(this._value);

  final ClientEventOneOf _value;

  @override
  ClientEventOneOf name(ClientEventOneOfNameEnum name) => call(name: name);

  @override
  ClientEventOneOf activityId(String activityId) =>
      call(activityId: activityId);

  @override
  ClientEventOneOf platform(ClientEventOneOfPlatformEnum? platform) =>
      call(platform: platform);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ClientEventOneOf(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ClientEventOneOf(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ClientEventOneOf call({
    Object? name = const $CopyWithPlaceholder(),
    Object? activityId = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
  }) {
    return ClientEventOneOf(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as ClientEventOneOfNameEnum,
      activityId:
          activityId == const $CopyWithPlaceholder() || activityId == null
          ? _value.activityId
          // ignore: cast_nullable_to_non_nullable
          : activityId as String,
      platform: platform == const $CopyWithPlaceholder()
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as ClientEventOneOfPlatformEnum?,
    );
  }
}

extension $ClientEventOneOfCopyWith on ClientEventOneOf {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfClientEventOneOf.copyWith(...)` or `instanceOfClientEventOneOf.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ClientEventOneOfCWProxy get copyWith => _$ClientEventOneOfCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientEventOneOf _$ClientEventOneOfFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ClientEventOneOf', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name', 'activityId']);
      final val = ClientEventOneOf(
        name: $checkedConvert(
          'name',
          (v) => $enumDecode(_$ClientEventOneOfNameEnumEnumMap, v),
        ),
        activityId: $checkedConvert('activityId', (v) => v as String),
        platform: $checkedConvert(
          'platform',
          (v) => $enumDecodeNullable(_$ClientEventOneOfPlatformEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ClientEventOneOfToJson(ClientEventOneOf instance) =>
    <String, dynamic>{
      'name': _$ClientEventOneOfNameEnumEnumMap[instance.name]!,
      'activityId': instance.activityId,
      'platform': ?_$ClientEventOneOfPlatformEnumEnumMap[instance.platform],
    };

const _$ClientEventOneOfNameEnumEnumMap = {
  ClientEventOneOfNameEnum.activityViewed: 'activity_viewed',
};

const _$ClientEventOneOfPlatformEnumEnumMap = {
  ClientEventOneOfPlatformEnum.web: 'web',
  ClientEventOneOfPlatformEnum.ios: 'ios',
  ClientEventOneOfPlatformEnum.android: 'android',
};
