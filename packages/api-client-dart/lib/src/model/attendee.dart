//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/member_person.dart';
import 'package:velio_api/src/model/attendance_mark.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attendee.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Attendee {
  /// Returns a new [Attendee] instance.
  Attendee({

    required  this.bookingId,

    required  this.ref,

    required  this.status,

    required  this.person,

    required  this.bookedAt,

    required  this.source_,

    required  this.invitedBy,

    required  this.planId,

    required  this.mark,

    required  this.markedAt,
  });

  @JsonKey(
    
    name: r'bookingId',
    required: true,
    includeIfNull: false,
  )


  final String bookingId;



  @JsonKey(
    
    name: r'ref',
    required: true,
    includeIfNull: false,
  )


  final String ref;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final AttendeeStatusEnum status;



  @JsonKey(
    
    name: r'person',
    required: true,
    includeIfNull: false,
  )


  final MemberPerson person;



  @JsonKey(
    
    name: r'bookedAt',
    required: true,
    includeIfNull: false,
  )


  final DateTime bookedAt;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final AttendeeSource_Enum source_;



  @JsonKey(
    
    name: r'invitedBy',
    required: true,
    includeIfNull: true,
  )


  final MemberPerson? invitedBy;



  @JsonKey(
    
    name: r'planId',
    required: true,
    includeIfNull: false,
  )


  final String planId;



  @JsonKey(
    
    name: r'mark',
    required: true,
    includeIfNull: true,
  )


  final AttendanceMark? mark;



  @JsonKey(
    
    name: r'markedAt',
    required: true,
    includeIfNull: true,
  )


  final DateTime? markedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Attendee &&
      other.bookingId == bookingId &&
      other.ref == ref &&
      other.status == status &&
      other.person == person &&
      other.bookedAt == bookedAt &&
      other.source_ == source_ &&
      other.invitedBy == invitedBy &&
      other.planId == planId &&
      other.mark == mark &&
      other.markedAt == markedAt;

    @override
    int get hashCode =>
        bookingId.hashCode +
        ref.hashCode +
        status.hashCode +
        person.hashCode +
        bookedAt.hashCode +
        source_.hashCode +
        (invitedBy == null ? 0 : invitedBy.hashCode) +
        planId.hashCode +
        (mark == null ? 0 : mark.hashCode) +
        (markedAt == null ? 0 : markedAt.hashCode);

  factory Attendee.fromJson(Map<String, dynamic> json) => _$AttendeeFromJson(json);

  Map<String, dynamic> toJson() => _$AttendeeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum AttendeeStatusEnum {
@JsonValue(r'confirmed')
confirmed(r'confirmed'),
@JsonValue(r'removed')
removed(r'removed');

const AttendeeStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


enum AttendeeSource_Enum {
@JsonValue(r'direct')
direct(r'direct'),
@JsonValue(r'vouch')
vouch(r'vouch'),
@JsonValue(r'public')
public(r'public');

const AttendeeSource_Enum(this.value);

final String value;

@override
String toString() => value;
}


