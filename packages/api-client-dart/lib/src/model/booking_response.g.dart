// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BookingResponseCWProxy {
  BookingResponse booking(Booking booking);

  BookingResponse activity(ActivityState activity);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  BookingResponse call({Booking booking, ActivityState activity});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBookingResponse.copyWith(...)` or call `instanceOfBookingResponse.copyWith.fieldName(value)` for a single field.
class _$BookingResponseCWProxyImpl implements _$BookingResponseCWProxy {
  const _$BookingResponseCWProxyImpl(this._value);

  final BookingResponse _value;

  @override
  BookingResponse booking(Booking booking) => call(booking: booking);

  @override
  BookingResponse activity(ActivityState activity) => call(activity: activity);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BookingResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BookingResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BookingResponse call({
    Object? booking = const $CopyWithPlaceholder(),
    Object? activity = const $CopyWithPlaceholder(),
  }) {
    return BookingResponse(
      booking: booking == const $CopyWithPlaceholder() || booking == null
          ? _value.booking
          // ignore: cast_nullable_to_non_nullable
          : booking as Booking,
      activity: activity == const $CopyWithPlaceholder() || activity == null
          ? _value.activity
          // ignore: cast_nullable_to_non_nullable
          : activity as ActivityState,
    );
  }
}

extension $BookingResponseCopyWith on BookingResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBookingResponse.copyWith(...)` or `instanceOfBookingResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BookingResponseCWProxy get copyWith => _$BookingResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingResponse _$BookingResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BookingResponse', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['booking', 'activity']);
      final val = BookingResponse(
        booking: $checkedConvert(
          'booking',
          (v) => Booking.fromJson(v as Map<String, dynamic>),
        ),
        activity: $checkedConvert(
          'activity',
          (v) => ActivityState.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$BookingResponseToJson(BookingResponse instance) =>
    <String, dynamic>{
      'booking': instance.booking.toJson(),
      'activity': instance.activity.toJson(),
    };
