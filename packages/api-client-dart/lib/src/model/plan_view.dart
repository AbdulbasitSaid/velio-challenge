//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/plan_view_viewer.dart';
import 'package:velio_api/src/model/plan_invite.dart';
import 'package:velio_api/src/model/plan_view_activity.dart';
import 'package:velio_api/src/model/member_person.dart';
import 'package:velio_api/src/model/plan_view_members_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan_view.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanView {
  /// Returns a new [PlanView] instance.
  PlanView({

    required  this.id,

    required  this.activity,

    required  this.owner,

    required  this.members,

    required  this.viewer,

    required  this.invites,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'activity',
    required: true,
    includeIfNull: false,
  )


  final PlanViewActivity activity;



  @JsonKey(
    
    name: r'owner',
    required: true,
    includeIfNull: false,
  )


  final MemberPerson owner;



  @JsonKey(
    
    name: r'members',
    required: true,
    includeIfNull: false,
  )


  final List<PlanViewMembersInner> members;



  @JsonKey(
    
    name: r'viewer',
    required: true,
    includeIfNull: false,
  )


  final PlanViewViewer viewer;



  @JsonKey(
    
    name: r'invites',
    required: true,
    includeIfNull: false,
  )


  final List<PlanInvite> invites;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlanView &&
      other.id == id &&
      other.activity == activity &&
      other.owner == owner &&
      other.members == members &&
      other.viewer == viewer &&
      other.invites == invites;

    @override
    int get hashCode =>
        id.hashCode +
        activity.hashCode +
        owner.hashCode +
        members.hashCode +
        viewer.hashCode +
        invites.hashCode;

  factory PlanView.fromJson(Map<String, dynamic> json) => _$PlanViewFromJson(json);

  Map<String, dynamic> toJson() => _$PlanViewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

