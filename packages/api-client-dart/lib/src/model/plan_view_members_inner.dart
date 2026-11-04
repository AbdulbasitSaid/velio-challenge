//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/member_person.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan_view_members_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanViewMembersInner {
  /// Returns a new [PlanViewMembersInner] instance.
  PlanViewMembersInner({

    required  this.person,

    required  this.source_,

    required  this.invitedBy,

    required  this.joinedAt,
  });

  @JsonKey(
    
    name: r'person',
    required: true,
    includeIfNull: false,
  )


  final MemberPerson person;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final PlanViewMembersInnerSource_Enum source_;



  @JsonKey(
    
    name: r'invitedBy',
    required: true,
    includeIfNull: true,
  )


  final MemberPerson? invitedBy;



  @JsonKey(
    
    name: r'joinedAt',
    required: true,
    includeIfNull: false,
  )


  final DateTime joinedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlanViewMembersInner &&
      other.person == person &&
      other.source_ == source_ &&
      other.invitedBy == invitedBy &&
      other.joinedAt == joinedAt;

    @override
    int get hashCode =>
        person.hashCode +
        source_.hashCode +
        (invitedBy == null ? 0 : invitedBy.hashCode) +
        joinedAt.hashCode;

  factory PlanViewMembersInner.fromJson(Map<String, dynamic> json) => _$PlanViewMembersInnerFromJson(json);

  Map<String, dynamic> toJson() => _$PlanViewMembersInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum PlanViewMembersInnerSource_Enum {
@JsonValue(r'direct')
direct(r'direct'),
@JsonValue(r'vouch')
vouch(r'vouch'),
@JsonValue(r'public')
public(r'public');

const PlanViewMembersInnerSource_Enum(this.value);

final String value;

@override
String toString() => value;
}


