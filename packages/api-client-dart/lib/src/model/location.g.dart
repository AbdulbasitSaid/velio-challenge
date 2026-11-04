// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LocationCWProxy {
  Location placeId(String? placeId);

  Location venueName(String venueName);

  Location addressText(String addressText);

  Location lat(num lat);

  Location lng(num lng);

  Location meetingPoint(String? meetingPoint);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Location(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Location(...).copyWith(id: 12, name: "My name")
  /// ```
  Location call({
    String? placeId,
    String venueName,
    String addressText,
    num lat,
    num lng,
    String? meetingPoint,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLocation.copyWith(...)` or call `instanceOfLocation.copyWith.fieldName(value)` for a single field.
class _$LocationCWProxyImpl implements _$LocationCWProxy {
  const _$LocationCWProxyImpl(this._value);

  final Location _value;

  @override
  Location placeId(String? placeId) => call(placeId: placeId);

  @override
  Location venueName(String venueName) => call(venueName: venueName);

  @override
  Location addressText(String addressText) => call(addressText: addressText);

  @override
  Location lat(num lat) => call(lat: lat);

  @override
  Location lng(num lng) => call(lng: lng);

  @override
  Location meetingPoint(String? meetingPoint) =>
      call(meetingPoint: meetingPoint);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Location(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Location(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Location call({
    Object? placeId = const $CopyWithPlaceholder(),
    Object? venueName = const $CopyWithPlaceholder(),
    Object? addressText = const $CopyWithPlaceholder(),
    Object? lat = const $CopyWithPlaceholder(),
    Object? lng = const $CopyWithPlaceholder(),
    Object? meetingPoint = const $CopyWithPlaceholder(),
  }) {
    return Location(
      placeId: placeId == const $CopyWithPlaceholder()
          ? _value.placeId
          // ignore: cast_nullable_to_non_nullable
          : placeId as String?,
      venueName: venueName == const $CopyWithPlaceholder() || venueName == null
          ? _value.venueName
          // ignore: cast_nullable_to_non_nullable
          : venueName as String,
      addressText:
          addressText == const $CopyWithPlaceholder() || addressText == null
          ? _value.addressText
          // ignore: cast_nullable_to_non_nullable
          : addressText as String,
      lat: lat == const $CopyWithPlaceholder() || lat == null
          ? _value.lat
          // ignore: cast_nullable_to_non_nullable
          : lat as num,
      lng: lng == const $CopyWithPlaceholder() || lng == null
          ? _value.lng
          // ignore: cast_nullable_to_non_nullable
          : lng as num,
      meetingPoint: meetingPoint == const $CopyWithPlaceholder()
          ? _value.meetingPoint
          // ignore: cast_nullable_to_non_nullable
          : meetingPoint as String?,
    );
  }
}

extension $LocationCopyWith on Location {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLocation.copyWith(...)` or `instanceOfLocation.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LocationCWProxy get copyWith => _$LocationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Location _$LocationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Location', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['venueName', 'addressText', 'lat', 'lng'],
      );
      final val = Location(
        placeId: $checkedConvert('placeId', (v) => v as String?),
        venueName: $checkedConvert('venueName', (v) => v as String),
        addressText: $checkedConvert('addressText', (v) => v as String),
        lat: $checkedConvert('lat', (v) => v as num),
        lng: $checkedConvert('lng', (v) => v as num),
        meetingPoint: $checkedConvert('meetingPoint', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
  'placeId': ?instance.placeId,
  'venueName': instance.venueName,
  'addressText': instance.addressText,
  'lat': instance.lat,
  'lng': instance.lng,
  'meetingPoint': ?instance.meetingPoint,
};
