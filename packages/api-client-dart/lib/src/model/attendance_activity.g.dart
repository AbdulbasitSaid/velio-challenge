// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_activity.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttendanceActivityCWProxy {
  AttendanceActivity id(String id);

  AttendanceActivity capacity(int capacity);

  AttendanceActivity spotsLeft(int spotsLeft);

  AttendanceActivity version(int version);

  AttendanceActivity startsAt(DateTime startsAt);

  AttendanceActivity timezone(String timezone);

  AttendanceActivity started(bool started);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AttendanceActivity(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AttendanceActivity(...).copyWith(id: 12, name: "My name")
  /// ```
  AttendanceActivity call({
    String id,
    int capacity,
    int spotsLeft,
    int version,
    DateTime startsAt,
    String timezone,
    bool started,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAttendanceActivity.copyWith(...)` or call `instanceOfAttendanceActivity.copyWith.fieldName(value)` for a single field.
class _$AttendanceActivityCWProxyImpl implements _$AttendanceActivityCWProxy {
  const _$AttendanceActivityCWProxyImpl(this._value);

  final AttendanceActivity _value;

  @override
  AttendanceActivity id(String id) => call(id: id);

  @override
  AttendanceActivity capacity(int capacity) => call(capacity: capacity);

  @override
  AttendanceActivity spotsLeft(int spotsLeft) => call(spotsLeft: spotsLeft);

  @override
  AttendanceActivity version(int version) => call(version: version);

  @override
  AttendanceActivity startsAt(DateTime startsAt) => call(startsAt: startsAt);

  @override
  AttendanceActivity timezone(String timezone) => call(timezone: timezone);

  @override
  AttendanceActivity started(bool started) => call(started: started);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AttendanceActivity(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AttendanceActivity(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AttendanceActivity call({
    Object? id = const $CopyWithPlaceholder(),
    Object? capacity = const $CopyWithPlaceholder(),
    Object? spotsLeft = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? startsAt = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
    Object? started = const $CopyWithPlaceholder(),
  }) {
    return AttendanceActivity(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      capacity: capacity == const $CopyWithPlaceholder() || capacity == null
          ? _value.capacity
          // ignore: cast_nullable_to_non_nullable
          : capacity as int,
      spotsLeft: spotsLeft == const $CopyWithPlaceholder() || spotsLeft == null
          ? _value.spotsLeft
          // ignore: cast_nullable_to_non_nullable
          : spotsLeft as int,
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      startsAt: startsAt == const $CopyWithPlaceholder() || startsAt == null
          ? _value.startsAt
          // ignore: cast_nullable_to_non_nullable
          : startsAt as DateTime,
      timezone: timezone == const $CopyWithPlaceholder() || timezone == null
          ? _value.timezone
          // ignore: cast_nullable_to_non_nullable
          : timezone as String,
      started: started == const $CopyWithPlaceholder() || started == null
          ? _value.started
          // ignore: cast_nullable_to_non_nullable
          : started as bool,
    );
  }
}

extension $AttendanceActivityCopyWith on AttendanceActivity {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAttendanceActivity.copyWith(...)` or `instanceOfAttendanceActivity.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttendanceActivityCWProxy get copyWith =>
      _$AttendanceActivityCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceActivity _$AttendanceActivityFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AttendanceActivity', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'capacity',
          'spotsLeft',
          'version',
          'startsAt',
          'timezone',
          'started',
        ],
      );
      final val = AttendanceActivity(
        id: $checkedConvert('id', (v) => v as String),
        capacity: $checkedConvert('capacity', (v) => (v as num).toInt()),
        spotsLeft: $checkedConvert('spotsLeft', (v) => (v as num).toInt()),
        version: $checkedConvert('version', (v) => (v as num).toInt()),
        startsAt: $checkedConvert(
          'startsAt',
          (v) => DateTime.parse(v as String),
        ),
        timezone: $checkedConvert('timezone', (v) => v as String),
        started: $checkedConvert('started', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$AttendanceActivityToJson(AttendanceActivity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'capacity': instance.capacity,
      'spotsLeft': instance.spotsLeft,
      'version': instance.version,
      'startsAt': instance.startsAt.toIso8601String(),
      'timezone': instance.timezone,
      'started': instance.started,
    };
