//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_activity.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminActivity {
  /// Returns a new [AdminActivity] instance.
  AdminActivity({

    required  this.id,

    required  this.title,

    required  this.communityName,

    required  this.startsAt,

    required  this.timezone,

    required  this.capacity,

    required  this.spotsLeft,

    required  this.bookingsPaused,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'communityName',
    required: true,
    includeIfNull: false,
  )


  final String communityName;



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
    
    name: r'bookingsPaused',
    required: true,
    includeIfNull: false,
  )


  final bool bookingsPaused;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminActivity &&
      other.id == id &&
      other.title == title &&
      other.communityName == communityName &&
      other.startsAt == startsAt &&
      other.timezone == timezone &&
      other.capacity == capacity &&
      other.spotsLeft == spotsLeft &&
      other.bookingsPaused == bookingsPaused;

    @override
    int get hashCode =>
        id.hashCode +
        title.hashCode +
        communityName.hashCode +
        startsAt.hashCode +
        timezone.hashCode +
        capacity.hashCode +
        spotsLeft.hashCode +
        bookingsPaused.hashCode;

  factory AdminActivity.fromJson(Map<String, dynamic> json) => _$AdminActivityFromJson(json);

  Map<String, dynamic> toJson() => _$AdminActivityToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

