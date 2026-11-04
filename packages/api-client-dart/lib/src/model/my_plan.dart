//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/my_plan_members.dart';
import 'package:velio_api/src/model/plan_view_viewer_booking.dart';
import 'package:velio_api/src/model/activity_card.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'my_plan.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MyPlan {
  /// Returns a new [MyPlan] instance.
  MyPlan({

    required  this.planId,

    required  this.activity,

    required  this.booking,

    required  this.members,
  });

  @JsonKey(
    
    name: r'planId',
    required: true,
    includeIfNull: false,
  )


  final String planId;



  @JsonKey(
    
    name: r'activity',
    required: true,
    includeIfNull: false,
  )


  final ActivityCard activity;



  @JsonKey(
    
    name: r'booking',
    required: true,
    includeIfNull: false,
  )


  final PlanViewViewerBooking booking;



  @JsonKey(
    
    name: r'members',
    required: true,
    includeIfNull: false,
  )


  final MyPlanMembers members;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MyPlan &&
      other.planId == planId &&
      other.activity == activity &&
      other.booking == booking &&
      other.members == members;

    @override
    int get hashCode =>
        planId.hashCode +
        activity.hashCode +
        booking.hashCode +
        members.hashCode;

  factory MyPlan.fromJson(Map<String, dynamic> json) => _$MyPlanFromJson(json);

  Map<String, dynamic> toJson() => _$MyPlanToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

