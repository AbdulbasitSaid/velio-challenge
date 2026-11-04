// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_location.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicLocationCWProxy {
  PublicLocation placeId(String? placeId);

  PublicLocation venueName(String venueName);

  PublicLocation addressText(String addressText);

  PublicLocation lat(num lat);

  PublicLocation lng(num lng);

  PublicLocation meetingPoint(String? meetingPoint);

  PublicLocation staticMapUrl(String? staticMapUrl);

  PublicLocation directionsUrl(String directionsUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicLocation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicLocation(...).copyWith(id: 12, name: "My name")
  /// ```
  PublicLocation call({
    String? placeId,
    String venueName,
    String addressText,
    num lat,
    num lng,
    String? meetingPoint,
    String? staticMapUrl,
    String directionsUrl,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPublicLocation.copyWith(...)` or call `instanceOfPublicLocation.copyWith.fieldName(value)` for a single field.
class _$PublicLocationCWProxyImpl implements _$PublicLocationCWProxy {
  const _$PublicLocationCWProxyImpl(this._value);

  final PublicLocation _value;

  @override
  PublicLocation placeId(String? placeId) => call(placeId: placeId);

  @override
  PublicLocation venueName(String venueName) => call(venueName: venueName);

  @override
  PublicLocation addressText(String addressText) =>
      call(addressText: addressText);

  @override
  PublicLocation lat(num lat) => call(lat: lat);

  @override
  PublicLocation lng(num lng) => call(lng: lng);

  @override
  PublicLocation meetingPoint(String? meetingPoint) =>
      call(meetingPoint: meetingPoint);

  @override
  PublicLocation staticMapUrl(String? staticMapUrl) =>
      call(staticMapUrl: staticMapUrl);

  @override
  PublicLocation directionsUrl(String directionsUrl) =>
      call(directionsUrl: directionsUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicLocation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicLocation(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PublicLocation call({
    Object? placeId = const $CopyWithPlaceholder(),
    Object? venueName = const $CopyWithPlaceholder(),
    Object? addressText = const $CopyWithPlaceholder(),
    Object? lat = const $CopyWithPlaceholder(),
    Object? lng = const $CopyWithPlaceholder(),
    Object? meetingPoint = const $CopyWithPlaceholder(),
    Object? staticMapUrl = const $CopyWithPlaceholder(),
    Object? directionsUrl = const $CopyWithPlaceholder(),
  }) {
    return PublicLocation(
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
      staticMapUrl: staticMapUrl == const $CopyWithPlaceholder()
          ? _value.staticMapUrl
          // ignore: cast_nullable_to_non_nullable
          : staticMapUrl as String?,
      directionsUrl:
          directionsUrl == const $CopyWithPlaceholder() || directionsUrl == null
          ? _value.directionsUrl
          // ignore: cast_nullable_to_non_nullable
          : directionsUrl as String,
    );
  }
}

extension $PublicLocationCopyWith on PublicLocation {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPublicLocation.copyWith(...)` or `instanceOfPublicLocation.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicLocationCWProxy get copyWith => _$PublicLocationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicLocation _$PublicLocationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublicLocation', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'placeId',
          'venueName',
          'addressText',
          'lat',
          'lng',
          'meetingPoint',
          'staticMapUrl',
          'directionsUrl',
        ],
      );
      final val = PublicLocation(
        placeId: $checkedConvert('placeId', (v) => v as String?),
        venueName: $checkedConvert('venueName', (v) => v as String),
        addressText: $checkedConvert('addressText', (v) => v as String),
        lat: $checkedConvert('lat', (v) => v as num),
        lng: $checkedConvert('lng', (v) => v as num),
        meetingPoint: $checkedConvert('meetingPoint', (v) => v as String?),
        staticMapUrl: $checkedConvert('staticMapUrl', (v) => v as String?),
        directionsUrl: $checkedConvert('directionsUrl', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$PublicLocationToJson(PublicLocation instance) =>
    <String, dynamic>{
      'placeId': instance.placeId,
      'venueName': instance.venueName,
      'addressText': instance.addressText,
      'lat': instance.lat,
      'lng': instance.lng,
      'meetingPoint': instance.meetingPoint,
      'staticMapUrl': instance.staticMapUrl,
      'directionsUrl': instance.directionsUrl,
    };
