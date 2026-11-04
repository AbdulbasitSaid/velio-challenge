// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_activity_viewer_booking.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicActivityViewerBookingCWProxy {
  PublicActivityViewerBooking id(String id);

  PublicActivityViewerBooking planId(String planId);

  PublicActivityViewerBooking status(
    PublicActivityViewerBookingStatusEnum status,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicActivityViewerBooking(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicActivityViewerBooking(...).copyWith(id: 12, name: "My name")
  /// ```
  PublicActivityViewerBooking call({
    String id,
    String planId,
    PublicActivityViewerBookingStatusEnum status,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPublicActivityViewerBooking.copyWith(...)` or call `instanceOfPublicActivityViewerBooking.copyWith.fieldName(value)` for a single field.
class _$PublicActivityViewerBookingCWProxyImpl
    implements _$PublicActivityViewerBookingCWProxy {
  const _$PublicActivityViewerBookingCWProxyImpl(this._value);

  final PublicActivityViewerBooking _value;

  @override
  PublicActivityViewerBooking id(String id) => call(id: id);

  @override
  PublicActivityViewerBooking planId(String planId) => call(planId: planId);

  @override
  PublicActivityViewerBooking status(
    PublicActivityViewerBookingStatusEnum status,
  ) => call(status: status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicActivityViewerBooking(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicActivityViewerBooking(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PublicActivityViewerBooking call({
    Object? id = const $CopyWithPlaceholder(),
    Object? planId = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return PublicActivityViewerBooking(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      planId: planId == const $CopyWithPlaceholder() || planId == null
          ? _value.planId
          // ignore: cast_nullable_to_non_nullable
          : planId as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as PublicActivityViewerBookingStatusEnum,
    );
  }
}

extension $PublicActivityViewerBookingCopyWith on PublicActivityViewerBooking {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPublicActivityViewerBooking.copyWith(...)` or `instanceOfPublicActivityViewerBooking.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicActivityViewerBookingCWProxy get copyWith =>
      _$PublicActivityViewerBookingCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicActivityViewerBooking _$PublicActivityViewerBookingFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PublicActivityViewerBooking', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'planId', 'status']);
  final val = PublicActivityViewerBooking(
    id: $checkedConvert('id', (v) => v as String),
    planId: $checkedConvert('planId', (v) => v as String),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$PublicActivityViewerBookingStatusEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$PublicActivityViewerBookingToJson(
  PublicActivityViewerBooking instance,
) => <String, dynamic>{
  'id': instance.id,
  'planId': instance.planId,
  'status': _$PublicActivityViewerBookingStatusEnumEnumMap[instance.status]!,
};

const _$PublicActivityViewerBookingStatusEnumEnumMap = {
  PublicActivityViewerBookingStatusEnum.confirmed: 'confirmed',
  PublicActivityViewerBookingStatusEnum.removed: 'removed',
};
