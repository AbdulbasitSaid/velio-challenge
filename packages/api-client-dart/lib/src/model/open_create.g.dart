// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$OpenCreateCWProxy {
  OpenCreate platform(OpenCreatePlatformEnum? platform);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OpenCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OpenCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  OpenCreate call({OpenCreatePlatformEnum? platform});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfOpenCreate.copyWith(...)` or call `instanceOfOpenCreate.copyWith.fieldName(value)` for a single field.
class _$OpenCreateCWProxyImpl implements _$OpenCreateCWProxy {
  const _$OpenCreateCWProxyImpl(this._value);

  final OpenCreate _value;

  @override
  OpenCreate platform(OpenCreatePlatformEnum? platform) =>
      call(platform: platform);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `OpenCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// OpenCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  OpenCreate call({Object? platform = const $CopyWithPlaceholder()}) {
    return OpenCreate(
      platform: platform == const $CopyWithPlaceholder()
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as OpenCreatePlatformEnum?,
    );
  }
}

extension $OpenCreateCopyWith on OpenCreate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfOpenCreate.copyWith(...)` or `instanceOfOpenCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$OpenCreateCWProxy get copyWith => _$OpenCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenCreate _$OpenCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('OpenCreate', json, ($checkedConvert) {
      final val = OpenCreate(
        platform: $checkedConvert(
          'platform',
          (v) => $enumDecodeNullable(_$OpenCreatePlatformEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$OpenCreateToJson(OpenCreate instance) =>
    <String, dynamic>{
      'platform': ?_$OpenCreatePlatformEnumEnumMap[instance.platform],
    };

const _$OpenCreatePlatformEnumEnumMap = {
  OpenCreatePlatformEnum.web: 'web',
  OpenCreatePlatformEnum.ios: 'ios',
  OpenCreatePlatformEnum.android: 'android',
};
