// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ClaimResponseCWProxy {
  ClaimResponse booking(Booking booking);

  ClaimResponse activity(ActivityState activity);

  ClaimResponse planId(String planId);

  ClaimResponse user(MemberPerson user);

  ClaimResponse token(String? token);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ClaimResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ClaimResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  ClaimResponse call({
    Booking booking,
    ActivityState activity,
    String planId,
    MemberPerson user,
    String? token,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfClaimResponse.copyWith(...)` or call `instanceOfClaimResponse.copyWith.fieldName(value)` for a single field.
class _$ClaimResponseCWProxyImpl implements _$ClaimResponseCWProxy {
  const _$ClaimResponseCWProxyImpl(this._value);

  final ClaimResponse _value;

  @override
  ClaimResponse booking(Booking booking) => call(booking: booking);

  @override
  ClaimResponse activity(ActivityState activity) => call(activity: activity);

  @override
  ClaimResponse planId(String planId) => call(planId: planId);

  @override
  ClaimResponse user(MemberPerson user) => call(user: user);

  @override
  ClaimResponse token(String? token) => call(token: token);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ClaimResponse(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ClaimResponse(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ClaimResponse call({
    Object? booking = const $CopyWithPlaceholder(),
    Object? activity = const $CopyWithPlaceholder(),
    Object? planId = const $CopyWithPlaceholder(),
    Object? user = const $CopyWithPlaceholder(),
    Object? token = const $CopyWithPlaceholder(),
  }) {
    return ClaimResponse(
      booking: booking == const $CopyWithPlaceholder() || booking == null
          ? _value.booking
          // ignore: cast_nullable_to_non_nullable
          : booking as Booking,
      activity: activity == const $CopyWithPlaceholder() || activity == null
          ? _value.activity
          // ignore: cast_nullable_to_non_nullable
          : activity as ActivityState,
      planId: planId == const $CopyWithPlaceholder() || planId == null
          ? _value.planId
          // ignore: cast_nullable_to_non_nullable
          : planId as String,
      user: user == const $CopyWithPlaceholder() || user == null
          ? _value.user
          // ignore: cast_nullable_to_non_nullable
          : user as MemberPerson,
      token: token == const $CopyWithPlaceholder()
          ? _value.token
          // ignore: cast_nullable_to_non_nullable
          : token as String?,
    );
  }
}

extension $ClaimResponseCopyWith on ClaimResponse {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfClaimResponse.copyWith(...)` or `instanceOfClaimResponse.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ClaimResponseCWProxy get copyWith => _$ClaimResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClaimResponse _$ClaimResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ClaimResponse', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['booking', 'activity', 'planId', 'user'],
      );
      final val = ClaimResponse(
        booking: $checkedConvert(
          'booking',
          (v) => Booking.fromJson(v as Map<String, dynamic>),
        ),
        activity: $checkedConvert(
          'activity',
          (v) => ActivityState.fromJson(v as Map<String, dynamic>),
        ),
        planId: $checkedConvert('planId', (v) => v as String),
        user: $checkedConvert(
          'user',
          (v) => MemberPerson.fromJson(v as Map<String, dynamic>),
        ),
        token: $checkedConvert('token', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ClaimResponseToJson(ClaimResponse instance) =>
    <String, dynamic>{
      'booking': instance.booking.toJson(),
      'activity': instance.activity.toJson(),
      'planId': instance.planId,
      'user': instance.user.toJson(),
      'token': ?instance.token,
    };
