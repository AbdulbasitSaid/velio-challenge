// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_envelope_error.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ErrorEnvelopeErrorCWProxy {
  ErrorEnvelopeError code(ErrorCode code);

  ErrorEnvelopeError message(String message);

  ErrorEnvelopeError requestId(String requestId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ErrorEnvelopeError(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ErrorEnvelopeError(...).copyWith(id: 12, name: "My name")
  /// ```
  ErrorEnvelopeError call({ErrorCode code, String message, String requestId});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfErrorEnvelopeError.copyWith(...)` or call `instanceOfErrorEnvelopeError.copyWith.fieldName(value)` for a single field.
class _$ErrorEnvelopeErrorCWProxyImpl implements _$ErrorEnvelopeErrorCWProxy {
  const _$ErrorEnvelopeErrorCWProxyImpl(this._value);

  final ErrorEnvelopeError _value;

  @override
  ErrorEnvelopeError code(ErrorCode code) => call(code: code);

  @override
  ErrorEnvelopeError message(String message) => call(message: message);

  @override
  ErrorEnvelopeError requestId(String requestId) => call(requestId: requestId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ErrorEnvelopeError(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ErrorEnvelopeError(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ErrorEnvelopeError call({
    Object? code = const $CopyWithPlaceholder(),
    Object? message = const $CopyWithPlaceholder(),
    Object? requestId = const $CopyWithPlaceholder(),
  }) {
    return ErrorEnvelopeError(
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as ErrorCode,
      message: message == const $CopyWithPlaceholder() || message == null
          ? _value.message
          // ignore: cast_nullable_to_non_nullable
          : message as String,
      requestId: requestId == const $CopyWithPlaceholder() || requestId == null
          ? _value.requestId
          // ignore: cast_nullable_to_non_nullable
          : requestId as String,
    );
  }
}

extension $ErrorEnvelopeErrorCopyWith on ErrorEnvelopeError {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfErrorEnvelopeError.copyWith(...)` or `instanceOfErrorEnvelopeError.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ErrorEnvelopeErrorCWProxy get copyWith =>
      _$ErrorEnvelopeErrorCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorEnvelopeError _$ErrorEnvelopeErrorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ErrorEnvelopeError', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['code', 'message', 'requestId']);
      final val = ErrorEnvelopeError(
        code: $checkedConvert(
          'code',
          (v) => $enumDecode(_$ErrorCodeEnumMap, v),
        ),
        message: $checkedConvert('message', (v) => v as String),
        requestId: $checkedConvert('requestId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ErrorEnvelopeErrorToJson(ErrorEnvelopeError instance) =>
    <String, dynamic>{
      'code': _$ErrorCodeEnumMap[instance.code]!,
      'message': instance.message,
      'requestId': instance.requestId,
    };

const _$ErrorCodeEnumMap = {
  ErrorCode.soldOut: 'sold_out',
  ErrorCode.alreadyBooked: 'already_booked',
  ErrorCode.alreadyClaimed: 'already_claimed',
  ErrorCode.inviteExpired: 'invite_expired',
  ErrorCode.invitePaused: 'invite_paused',
  ErrorCode.activityStarted: 'activity_started',
  ErrorCode.bookingsPaused: 'bookings_paused',
  ErrorCode.invalidCode: 'invalid_code',
  ErrorCode.rateLimited: 'rate_limited',
  ErrorCode.idempotencyConflict: 'idempotency_conflict',
  ErrorCode.bookingRemoved: 'booking_removed',
  ErrorCode.activityNotStarted: 'activity_not_started',
  ErrorCode.locationLocked: 'location_locked',
  ErrorCode.capacityBelowBookings: 'capacity_below_bookings',
  ErrorCode.invitesUnavailable: 'invites_unavailable',
  ErrorCode.invalidContact: 'invalid_contact',
  ErrorCode.validationFailed: 'validation_failed',
  ErrorCode.unauthenticated: 'unauthenticated',
  ErrorCode.forbidden: 'forbidden',
  ErrorCode.notFound: 'not_found',
  ErrorCode.internal: 'internal',
};
