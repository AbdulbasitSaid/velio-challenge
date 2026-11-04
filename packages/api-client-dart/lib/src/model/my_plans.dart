//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/my_plan.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'my_plans.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MyPlans {
  /// Returns a new [MyPlans] instance.
  MyPlans({

    required  this.upcoming,

    required  this.past,
  });

  @JsonKey(
    
    name: r'upcoming',
    required: true,
    includeIfNull: false,
  )


  final List<MyPlan> upcoming;



  @JsonKey(
    
    name: r'past',
    required: true,
    includeIfNull: false,
  )


  final List<MyPlan> past;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MyPlans &&
      other.upcoming == upcoming &&
      other.past == past;

    @override
    int get hashCode =>
        upcoming.hashCode +
        past.hashCode;

  factory MyPlans.fromJson(Map<String, dynamic> json) => _$MyPlansFromJson(json);

  Map<String, dynamic> toJson() => _$MyPlansToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

