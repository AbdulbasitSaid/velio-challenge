// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_mark_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttendanceMarkCreateCWProxy {
  AttendanceMarkCreate mark(AttendanceMark? mark);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AttendanceMarkCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AttendanceMarkCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  AttendanceMarkCreate call({AttendanceMark? mark});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAttendanceMarkCreate.copyWith(...)` or call `instanceOfAttendanceMarkCreate.copyWith.fieldName(value)` for a single field.
class _$AttendanceMarkCreateCWProxyImpl
    implements _$AttendanceMarkCreateCWProxy {
  const _$AttendanceMarkCreateCWProxyImpl(this._value);

  final AttendanceMarkCreate _value;

  @override
  AttendanceMarkCreate mark(AttendanceMark? mark) => call(mark: mark);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AttendanceMarkCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AttendanceMarkCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AttendanceMarkCreate call({Object? mark = const $CopyWithPlaceholder()}) {
    return AttendanceMarkCreate(
      mark: mark == const $CopyWithPlaceholder()
          ? _value.mark
          // ignore: cast_nullable_to_non_nullable
          : mark as AttendanceMark?,
    );
  }
}

extension $AttendanceMarkCreateCopyWith on AttendanceMarkCreate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAttendanceMarkCreate.copyWith(...)` or `instanceOfAttendanceMarkCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttendanceMarkCreateCWProxy get copyWith =>
      _$AttendanceMarkCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceMarkCreate _$AttendanceMarkCreateFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AttendanceMarkCreate', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['mark']);
  final val = AttendanceMarkCreate(
    mark: $checkedConvert(
      'mark',
      (v) => $enumDecodeNullable(_$AttendanceMarkEnumMap, v),
    ),
  );
  return val;
});

Map<String, dynamic> _$AttendanceMarkCreateToJson(
  AttendanceMarkCreate instance,
) => <String, dynamic>{'mark': _$AttendanceMarkEnumMap[instance.mark]};

const _$AttendanceMarkEnumMap = {
  AttendanceMark.attended: 'attended',
  AttendanceMark.noShow: 'no_show',
};
