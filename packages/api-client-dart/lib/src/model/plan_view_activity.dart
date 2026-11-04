//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan_view_activity.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanViewActivity {
  /// Returns a new [PlanViewActivity] instance.
  PlanViewActivity({

    required  this.id,

    required  this.title,

    required  this.startsAt,

    required  this.timezone,
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





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlanViewActivity &&
      other.id == id &&
      other.title == title &&
      other.startsAt == startsAt &&
      other.timezone == timezone;

    @override
    int get hashCode =>
        id.hashCode +
        title.hashCode +
        startsAt.hashCode +
        timezone.hashCode;

  factory PlanViewActivity.fromJson(Map<String, dynamic> json) => _$PlanViewActivityFromJson(json);

  Map<String, dynamic> toJson() => _$PlanViewActivityToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

