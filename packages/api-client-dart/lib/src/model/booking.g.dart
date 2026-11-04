// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BookingCWProxy {
  Booking id(String id);

  Booking ref(String ref);

  Booking activityId(String activityId);

  Booking planId(String planId);

  Booking source_(BookingSource_Enum source_);

  Booking status(BookingStatusEnum status);

  Booking createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Booking(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Booking(...).copyWith(id: 12, name: "My name")
  /// ```
  Booking call({
    String id,
    String ref,
    String activityId,
    String planId,
    BookingSource_Enum source_,
    BookingStatusEnum status,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBooking.copyWith(...)` or call `instanceOfBooking.copyWith.fieldName(value)` for a single field.
class _$BookingCWProxyImpl implements _$BookingCWProxy {
  const _$BookingCWProxyImpl(this._value);

  final Booking _value;

  @override
  Booking id(String id) => call(id: id);

  @override
  Booking ref(String ref) => call(ref: ref);

  @override
  Booking activityId(String activityId) => call(activityId: activityId);

  @override
  Booking planId(String planId) => call(planId: planId);

  @override
  Booking source_(BookingSource_Enum source_) => call(source_: source_);

  @override
  Booking status(BookingStatusEnum status) => call(status: status);

  @override
  Booking createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Booking(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Booking(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Booking call({
    Object? id = const $CopyWithPlaceholder(),
    Object? ref = const $CopyWithPlaceholder(),
    Object? activityId = const $CopyWithPlaceholder(),
    Object? planId = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Booking(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      ref: ref == const $CopyWithPlaceholder() || ref == null
          ? _value.ref
          // ignore: cast_nullable_to_non_nullable
          : ref as String,
      activityId:
          activityId == const $CopyWithPlaceholder() || activityId == null
          ? _value.activityId
          // ignore: cast_nullable_to_non_nullable
          : activityId as String,
      planId: planId == const $CopyWithPlaceholder() || planId == null
          ? _value.planId
          // ignore: cast_nullable_to_non_nullable
          : planId as String,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as BookingSource_Enum,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as BookingStatusEnum,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $BookingCopyWith on Booking {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBooking.copyWith(...)` or `instanceOfBooking.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BookingCWProxy get copyWith => _$BookingCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Booking _$BookingFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Booking', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'ref',
          'activityId',
          'planId',
          'source',
          'status',
          'createdAt',
        ],
      );
      final val = Booking(
        id: $checkedConvert('id', (v) => v as String),
        ref: $checkedConvert('ref', (v) => v as String),
        activityId: $checkedConvert('activityId', (v) => v as String),
        planId: $checkedConvert('planId', (v) => v as String),
        source_: $checkedConvert(
          'source',
          (v) => $enumDecode(_$BookingSource_EnumEnumMap, v),
        ),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$BookingStatusEnumEnumMap, v),
        ),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$BookingToJson(Booking instance) => <String, dynamic>{
  'id': instance.id,
  'ref': instance.ref,
  'activityId': instance.activityId,
  'planId': instance.planId,
  'source': _$BookingSource_EnumEnumMap[instance.source_]!,
  'status': _$BookingStatusEnumEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$BookingSource_EnumEnumMap = {
  BookingSource_Enum.direct: 'direct',
  BookingSource_Enum.vouch: 'vouch',
  BookingSource_Enum.public: 'public',
};

const _$BookingStatusEnumEnumMap = {
  BookingStatusEnum.confirmed: 'confirmed',
  BookingStatusEnum.removed: 'removed',
};
