// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttendanceCWProxy {
  Attendance activity(AttendanceActivity activity);

  Attendance attendees(List<Attendee> attendees);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Attendance(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Attendance(...).copyWith(id: 12, name: "My name")
  /// ```
  Attendance call({AttendanceActivity activity, List<Attendee> attendees});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAttendance.copyWith(...)` or call `instanceOfAttendance.copyWith.fieldName(value)` for a single field.
class _$AttendanceCWProxyImpl implements _$AttendanceCWProxy {
  const _$AttendanceCWProxyImpl(this._value);

  final Attendance _value;

  @override
  Attendance activity(AttendanceActivity activity) => call(activity: activity);

  @override
  Attendance attendees(List<Attendee> attendees) => call(attendees: attendees);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Attendance(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Attendance(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Attendance call({
    Object? activity = const $CopyWithPlaceholder(),
    Object? attendees = const $CopyWithPlaceholder(),
  }) {
    return Attendance(
      activity: activity == const $CopyWithPlaceholder() || activity == null
          ? _value.activity
          // ignore: cast_nullable_to_non_nullable
          : activity as AttendanceActivity,
      attendees: attendees == const $CopyWithPlaceholder() || attendees == null
          ? _value.attendees
          // ignore: cast_nullable_to_non_nullable
          : attendees as List<Attendee>,
    );
  }
}

extension $AttendanceCopyWith on Attendance {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAttendance.copyWith(...)` or `instanceOfAttendance.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttendanceCWProxy get copyWith => _$AttendanceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Attendance _$AttendanceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Attendance', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['activity', 'attendees']);
      final val = Attendance(
        activity: $checkedConvert(
          'activity',
          (v) => AttendanceActivity.fromJson(v as Map<String, dynamic>),
        ),
        attendees: $checkedConvert(
          'attendees',
          (v) => (v as List<dynamic>)
              .map((e) => Attendee.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AttendanceToJson(Attendance instance) =>
    <String, dynamic>{
      'activity': instance.activity.toJson(),
      'attendees': instance.attendees.map((e) => e.toJson()).toList(),
    };
