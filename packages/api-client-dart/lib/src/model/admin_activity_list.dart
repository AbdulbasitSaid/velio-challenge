//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/admin_activity.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_activity_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminActivityList {
  /// Returns a new [AdminActivityList] instance.
  AdminActivityList({

    required  this.activities,
  });

  @JsonKey(
    
    name: r'activities',
    required: true,
    includeIfNull: false,
  )


  final List<AdminActivity> activities;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminActivityList &&
      other.activities == activities;

    @override
    int get hashCode =>
        activities.hashCode;

  factory AdminActivityList.fromJson(Map<String, dynamic> json) => _$AdminActivityListFromJson(json);

  Map<String, dynamic> toJson() => _$AdminActivityListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

