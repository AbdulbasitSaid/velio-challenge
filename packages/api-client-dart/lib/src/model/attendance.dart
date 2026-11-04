//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/attendee.dart';
import 'package:velio_api/src/model/attendance_activity.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attendance.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Attendance {
  /// Returns a new [Attendance] instance.
  Attendance({

    required  this.activity,

    required  this.attendees,
  });

  @JsonKey(
    
    name: r'activity',
    required: true,
    includeIfNull: false,
  )


  final AttendanceActivity activity;



  @JsonKey(
    
    name: r'attendees',
    required: true,
    includeIfNull: false,
  )


  final List<Attendee> attendees;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Attendance &&
      other.activity == activity &&
      other.attendees == attendees;

    @override
    int get hashCode =>
        activity.hashCode +
        attendees.hashCode;

  factory Attendance.fromJson(Map<String, dynamic> json) => _$AttendanceFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

