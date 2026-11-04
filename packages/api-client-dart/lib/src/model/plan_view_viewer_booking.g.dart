// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_view_viewer_booking.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlanViewViewerBookingCWProxy {
  PlanViewViewerBooking id(String id);

  PlanViewViewerBooking ref(String ref);

  PlanViewViewerBooking status(PlanViewViewerBookingStatusEnum status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlanViewViewerBooking(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlanViewViewerBooking(...).copyWith(id: 12, name: "My name")
  /// ```
  PlanViewViewerBooking call({
    String id,
    String ref,
    PlanViewViewerBookingStatusEnum status,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPlanViewViewerBooking.copyWith(...)` or call `instanceOfPlanViewViewerBooking.copyWith.fieldName(value)` for a single field.
class _$PlanViewViewerBookingCWProxyImpl
    implements _$PlanViewViewerBookingCWProxy {
  const _$PlanViewViewerBookingCWProxyImpl(this._value);

  final PlanViewViewerBooking _value;

  @override
  PlanViewViewerBooking id(String id) => call(id: id);

  @override
  PlanViewViewerBooking ref(String ref) => call(ref: ref);

  @override
  PlanViewViewerBooking status(PlanViewViewerBookingStatusEnum status) =>
      call(status: status);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlanViewViewerBooking(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlanViewViewerBooking(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PlanViewViewerBooking call({
    Object? id = const $CopyWithPlaceholder(),
    Object? ref = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
  }) {
    return PlanViewViewerBooking(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      ref: ref == const $CopyWithPlaceholder() || ref == null
          ? _value.ref
          // ignore: cast_nullable_to_non_nullable
          : ref as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as PlanViewViewerBookingStatusEnum,
    );
  }
}

extension $PlanViewViewerBookingCopyWith on PlanViewViewerBooking {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPlanViewViewerBooking.copyWith(...)` or `instanceOfPlanViewViewerBooking.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlanViewViewerBookingCWProxy get copyWith =>
      _$PlanViewViewerBookingCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanViewViewerBooking _$PlanViewViewerBookingFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PlanViewViewerBooking', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'ref', 'status']);
  final val = PlanViewViewerBooking(
    id: $checkedConvert('id', (v) => v as String),
    ref: $checkedConvert('ref', (v) => v as String),
    status: $checkedConvert(
      'status',
      (v) => $enumDecode(_$PlanViewViewerBookingStatusEnumEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$PlanViewViewerBookingToJson(
  PlanViewViewerBooking instance,
) => <String, dynamic>{
  'id': instance.id,
  'ref': instance.ref,
  'status': _$PlanViewViewerBookingStatusEnumEnumMap[instance.status]!,
};

const _$PlanViewViewerBookingStatusEnumEnumMap = {
  PlanViewViewerBookingStatusEnum.confirmed: 'confirmed',
  PlanViewViewerBookingStatusEnum.removed: 'removed',
};
