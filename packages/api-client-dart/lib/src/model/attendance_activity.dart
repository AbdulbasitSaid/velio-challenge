//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'attendance_activity.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AttendanceActivity {
  /// Returns a new [AttendanceActivity] instance.
  AttendanceActivity({

    required  this.id,

    required  this.capacity,

    required  this.spotsLeft,

    required  this.version,

    required  this.startsAt,

    required  this.timezone,

    required  this.started,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'capacity',
    required: true,
    includeIfNull: false,
  )


  final int capacity;



  @JsonKey(
    
    name: r'spotsLeft',
    required: true,
    includeIfNull: false,
  )


  final int spotsLeft;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;



  @JsonKey(
    
    name: r'startsAt',
    required: true,
    includeIfNull: false,
  )


  final DateTime startsAt;



  @JsonKey(
    
    name: r'timezone',
    required: true,
    includeIfNull: false,
  )


  final String timezone;



  @JsonKey(
    
    name: r'started',
    required: true,
    includeIfNull: false,
  )


  final bool started;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AttendanceActivity &&
      other.id == id &&
      other.capacity == capacity &&
      other.spotsLeft == spotsLeft &&
      other.version == version &&
      other.startsAt == startsAt &&
      other.timezone == timezone &&
      other.started == started;

    @override
    int get hashCode =>
        id.hashCode +
        capacity.hashCode +
        spotsLeft.hashCode +
        version.hashCode +
        startsAt.hashCode +
        timezone.hashCode +
        started.hashCode;

  factory AttendanceActivity.fromJson(Map<String, dynamic> json) => _$AttendanceActivityFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceActivityToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

