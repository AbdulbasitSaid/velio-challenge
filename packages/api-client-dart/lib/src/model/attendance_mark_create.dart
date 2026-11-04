//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/attendance_mark.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attendance_mark_create.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AttendanceMarkCreate {
  /// Returns a new [AttendanceMarkCreate] instance.
  AttendanceMarkCreate({

    required  this.mark,
  });

  @JsonKey(
    
    name: r'mark',
    required: true,
    includeIfNull: true,
  )


  final AttendanceMark? mark;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AttendanceMarkCreate &&
      other.mark == mark;

    @override
    int get hashCode =>
        (mark == null ? 0 : mark.hashCode);

  factory AttendanceMarkCreate.fromJson(Map<String, dynamic> json) => _$AttendanceMarkCreateFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceMarkCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

