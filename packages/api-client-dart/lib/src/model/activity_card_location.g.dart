// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_card_location.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ActivityCardLocationCWProxy {
  ActivityCardLocation venueName(String venueName);

  ActivityCardLocation lat(num lat);

  ActivityCardLocation lng(num lng);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActivityCardLocation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActivityCardLocation(...).copyWith(id: 12, name: "My name")
  /// ```
  ActivityCardLocation call({String venueName, num lat, num lng});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfActivityCardLocation.copyWith(...)` or call `instanceOfActivityCardLocation.copyWith.fieldName(value)` for a single field.
class _$ActivityCardLocationCWProxyImpl
    implements _$ActivityCardLocationCWProxy {
  const _$ActivityCardLocationCWProxyImpl(this._value);

  final ActivityCardLocation _value;

  @override
  ActivityCardLocation venueName(String venueName) =>
      call(venueName: venueName);

  @override
  ActivityCardLocation lat(num lat) => call(lat: lat);

  @override
  ActivityCardLocation lng(num lng) => call(lng: lng);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActivityCardLocation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActivityCardLocation(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ActivityCardLocation call({
    Object? venueName = const $CopyWithPlaceholder(),
    Object? lat = const $CopyWithPlaceholder(),
    Object? lng = const $CopyWithPlaceholder(),
  }) {
    return ActivityCardLocation(
      venueName: venueName == const $CopyWithPlaceholder() || venueName == null
          ? _value.venueName
          // ignore: cast_nullable_to_non_nullable
          : venueName as String,
      lat: lat == const $CopyWithPlaceholder() || lat == null
          ? _value.lat
          // ignore: cast_nullable_to_non_nullable
          : lat as num,
      lng: lng == const $CopyWithPlaceholder() || lng == null
          ? _value.lng
          // ignore: cast_nullable_to_non_nullable
          : lng as num,
    );
  }
}

extension $ActivityCardLocationCopyWith on ActivityCardLocation {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfActivityCardLocation.copyWith(...)` or `instanceOfActivityCardLocation.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ActivityCardLocationCWProxy get copyWith =>
      _$ActivityCardLocationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityCardLocation _$ActivityCardLocationFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ActivityCardLocation', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['venueName', 'lat', 'lng']);
  final val = ActivityCardLocation(
    venueName: $checkedConvert('venueName', (v) => v as String),
    lat: $checkedConvert('lat', (v) => v as num),
    lng: $checkedConvert('lng', (v) => v as num),
  );
  return val;
});

Map<String, dynamic> _$ActivityCardLocationToJson(
  ActivityCardLocation instance,
) => <String, dynamic>{
  'venueName': instance.venueName,
  'lat': instance.lat,
  'lng': instance.lng,
};
