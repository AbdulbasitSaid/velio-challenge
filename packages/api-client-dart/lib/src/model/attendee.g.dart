// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendee.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AttendeeCWProxy {
  Attendee bookingId(String bookingId);

  Attendee ref(String ref);

  Attendee status(AttendeeStatusEnum status);

  Attendee person(MemberPerson person);

  Attendee bookedAt(DateTime bookedAt);

  Attendee source_(AttendeeSource_Enum source_);

  Attendee invitedBy(MemberPerson? invitedBy);

  Attendee planId(String planId);

  Attendee mark(AttendanceMark? mark);

  Attendee markedAt(DateTime? markedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Attendee(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Attendee(...).copyWith(id: 12, name: "My name")
  /// ```
  Attendee call({
    String bookingId,
    String ref,
    AttendeeStatusEnum status,
    MemberPerson person,
    DateTime bookedAt,
    AttendeeSource_Enum source_,
    MemberPerson? invitedBy,
    String planId,
    AttendanceMark? mark,
    DateTime? markedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAttendee.copyWith(...)` or call `instanceOfAttendee.copyWith.fieldName(value)` for a single field.
class _$AttendeeCWProxyImpl implements _$AttendeeCWProxy {
  const _$AttendeeCWProxyImpl(this._value);

  final Attendee _value;

  @override
  Attendee bookingId(String bookingId) => call(bookingId: bookingId);

  @override
  Attendee ref(String ref) => call(ref: ref);

  @override
  Attendee status(AttendeeStatusEnum status) => call(status: status);

  @override
  Attendee person(MemberPerson person) => call(person: person);

  @override
  Attendee bookedAt(DateTime bookedAt) => call(bookedAt: bookedAt);

  @override
  Attendee source_(AttendeeSource_Enum source_) => call(source_: source_);

  @override
  Attendee invitedBy(MemberPerson? invitedBy) => call(invitedBy: invitedBy);

  @override
  Attendee planId(String planId) => call(planId: planId);

  @override
  Attendee mark(AttendanceMark? mark) => call(mark: mark);

  @override
  Attendee markedAt(DateTime? markedAt) => call(markedAt: markedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Attendee(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Attendee(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Attendee call({
    Object? bookingId = const $CopyWithPlaceholder(),
    Object? ref = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? person = const $CopyWithPlaceholder(),
    Object? bookedAt = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? invitedBy = const $CopyWithPlaceholder(),
    Object? planId = const $CopyWithPlaceholder(),
    Object? mark = const $CopyWithPlaceholder(),
    Object? markedAt = const $CopyWithPlaceholder(),
  }) {
    return Attendee(
      bookingId: bookingId == const $CopyWithPlaceholder() || bookingId == null
          ? _value.bookingId
          // ignore: cast_nullable_to_non_nullable
          : bookingId as String,
      ref: ref == const $CopyWithPlaceholder() || ref == null
          ? _value.ref
          // ignore: cast_nullable_to_non_nullable
          : ref as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as AttendeeStatusEnum,
      person: person == const $CopyWithPlaceholder() || person == null
          ? _value.person
          // ignore: cast_nullable_to_non_nullable
          : person as MemberPerson,
      bookedAt: bookedAt == const $CopyWithPlaceholder() || bookedAt == null
          ? _value.bookedAt
          // ignore: cast_nullable_to_non_nullable
          : bookedAt as DateTime,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as AttendeeSource_Enum,
      invitedBy: invitedBy == const $CopyWithPlaceholder()
          ? _value.invitedBy
          // ignore: cast_nullable_to_non_nullable
          : invitedBy as MemberPerson?,
      planId: planId == const $CopyWithPlaceholder() || planId == null
          ? _value.planId
          // ignore: cast_nullable_to_non_nullable
          : planId as String,
      mark: mark == const $CopyWithPlaceholder()
          ? _value.mark
          // ignore: cast_nullable_to_non_nullable
          : mark as AttendanceMark?,
      markedAt: markedAt == const $CopyWithPlaceholder()
          ? _value.markedAt
          // ignore: cast_nullable_to_non_nullable
          : markedAt as DateTime?,
    );
  }
}

extension $AttendeeCopyWith on Attendee {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAttendee.copyWith(...)` or `instanceOfAttendee.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AttendeeCWProxy get copyWith => _$AttendeeCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Attendee _$AttendeeFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Attendee',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'bookingId',
        'ref',
        'status',
        'person',
        'bookedAt',
        'source',
        'invitedBy',
        'planId',
        'mark',
        'markedAt',
      ],
    );
    final val = Attendee(
      bookingId: $checkedConvert('bookingId', (v) => v as String),
      ref: $checkedConvert('ref', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$AttendeeStatusEnumEnumMap, v),
      ),
      person: $checkedConvert(
        'person',
        (v) => MemberPerson.fromJson(v as Map<String, dynamic>),
      ),
      bookedAt: $checkedConvert('bookedAt', (v) => DateTime.parse(v as String)),
      source_: $checkedConvert(
        'source',
        (v) => $enumDecode(_$AttendeeSource_EnumEnumMap, v),
      ),
      invitedBy: $checkedConvert(
        'invitedBy',
        (v) =>
            v == null ? null : MemberPerson.fromJson(v as Map<String, dynamic>),
      ),
      planId: $checkedConvert('planId', (v) => v as String),
      mark: $checkedConvert(
        'mark',
        (v) => $enumDecodeNullable(_$AttendanceMarkEnumMap, v),
      ),
      markedAt: $checkedConvert(
        'markedAt',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'source_': 'source'},
);

Map<String, dynamic> _$AttendeeToJson(Attendee instance) => <String, dynamic>{
  'bookingId': instance.bookingId,
  'ref': instance.ref,
  'status': _$AttendeeStatusEnumEnumMap[instance.status]!,
  'person': instance.person.toJson(),
  'bookedAt': instance.bookedAt.toIso8601String(),
  'source': _$AttendeeSource_EnumEnumMap[instance.source_]!,
  'invitedBy': instance.invitedBy?.toJson(),
  'planId': instance.planId,
  'mark': _$AttendanceMarkEnumMap[instance.mark],
  'markedAt': instance.markedAt?.toIso8601String(),
};

const _$AttendeeStatusEnumEnumMap = {
  AttendeeStatusEnum.confirmed: 'confirmed',
  AttendeeStatusEnum.removed: 'removed',
};

const _$AttendeeSource_EnumEnumMap = {
  AttendeeSource_Enum.direct: 'direct',
  AttendeeSource_Enum.vouch: 'vouch',
  AttendeeSource_Enum.public: 'public',
};

const _$AttendanceMarkEnumMap = {
  AttendanceMark.attended: 'attended',
  AttendanceMark.noShow: 'no_show',
};
