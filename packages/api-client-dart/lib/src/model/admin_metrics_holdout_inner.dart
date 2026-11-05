//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/ratio.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_metrics_holdout_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMetricsHoldoutInner {
  /// Returns a new [AdminMetricsHoldoutInner] instance.
  AdminMetricsHoldoutInner({

    required  this.arm,

    required  this.users,

    required  this.bookers,

    required  this.newUsersPerBooker,

    required  this.plansHappened,
  });

  @JsonKey(
    
    name: r'arm',
    required: true,
    includeIfNull: false,
  )


  final AdminMetricsHoldoutInnerArmEnum arm;



  @JsonKey(
    
    name: r'users',
    required: true,
    includeIfNull: false,
  )


  final int users;



  @JsonKey(
    
    name: r'bookers',
    required: true,
    includeIfNull: false,
  )


  final int bookers;



  @JsonKey(
    
    name: r'newUsersPerBooker',
    required: true,
    includeIfNull: false,
  )


  final Ratio newUsersPerBooker;



  @JsonKey(
    
    name: r'plansHappened',
    required: true,
    includeIfNull: false,
  )


  final Ratio plansHappened;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminMetricsHoldoutInner &&
      other.arm == arm &&
      other.users == users &&
      other.bookers == bookers &&
      other.newUsersPerBooker == newUsersPerBooker &&
      other.plansHappened == plansHappened;

    @override
    int get hashCode =>
        arm.hashCode +
        users.hashCode +
        bookers.hashCode +
        newUsersPerBooker.hashCode +
        plansHappened.hashCode;

  factory AdminMetricsHoldoutInner.fromJson(Map<String, dynamic> json) => _$AdminMetricsHoldoutInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMetricsHoldoutInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum AdminMetricsHoldoutInnerArmEnum {
@JsonValue(r'exposed')
exposed(r'exposed'),
@JsonValue(r'holdout')
holdout(r'holdout');

const AdminMetricsHoldoutInnerArmEnum(this.value);

final String value;

@override
String toString() => value;
}


