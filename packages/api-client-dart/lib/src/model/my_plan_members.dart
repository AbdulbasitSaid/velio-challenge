//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/member_person.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'my_plan_members.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MyPlanMembers {
  /// Returns a new [MyPlanMembers] instance.
  MyPlanMembers({

    required  this.count,

    required  this.preview,
  });

  @JsonKey(
    
    name: r'count',
    required: true,
    includeIfNull: false,
  )


  final int count;



  @JsonKey(
    
    name: r'preview',
    required: true,
    includeIfNull: false,
  )


  final List<MemberPerson> preview;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MyPlanMembers &&
      other.count == count &&
      other.preview == preview;

    @override
    int get hashCode =>
        count.hashCode +
        preview.hashCode;

  factory MyPlanMembers.fromJson(Map<String, dynamic> json) => _$MyPlanMembersFromJson(json);

  Map<String, dynamic> toJson() => _$MyPlanMembersToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

