//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/invite_status.dart';
import 'package:velio_api/src/model/pause_reason.dart';
import 'package:velio_api/src/model/member_person.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan_invite.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanInvite {
  /// Returns a new [PlanInvite] instance.
  PlanInvite({

    required  this.id,

    required  this.rail,

    required  this.inviteeName,

    required  this.createdBy,

    required  this.status,

    required  this.opens,

    required  this.claims,

    required  this.paused,

    required  this.pausedReason,

    required  this.createdAt,

     this.code,

     this.link,

     this.note,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'rail',
    required: true,
    includeIfNull: false,
  )


  final PlanInviteRailEnum rail;



  @JsonKey(
    
    name: r'inviteeName',
    required: true,
    includeIfNull: true,
  )


  final String? inviteeName;



  @JsonKey(
    
    name: r'createdBy',
    required: true,
    includeIfNull: false,
  )


  final MemberPerson createdBy;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final InviteStatus status;



  @JsonKey(
    
    name: r'opens',
    required: true,
    includeIfNull: false,
  )


  final int opens;



  @JsonKey(
    
    name: r'claims',
    required: true,
    includeIfNull: false,
  )


  final int claims;



  @JsonKey(
    
    name: r'paused',
    required: true,
    includeIfNull: false,
  )


  final bool paused;



  @JsonKey(
    
    name: r'pausedReason',
    required: true,
    includeIfNull: true,
  )


  final PauseReason? pausedReason;



  @JsonKey(
    
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'code',
    required: false,
    includeIfNull: false,
  )


  final String? code;



  @JsonKey(
    
    name: r'link',
    required: false,
    includeIfNull: false,
  )


  final String? link;



  @JsonKey(
    
    name: r'note',
    required: false,
    includeIfNull: false,
  )


  final String? note;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlanInvite &&
      other.id == id &&
      other.rail == rail &&
      other.inviteeName == inviteeName &&
      other.createdBy == createdBy &&
      other.status == status &&
      other.opens == opens &&
      other.claims == claims &&
      other.paused == paused &&
      other.pausedReason == pausedReason &&
      other.createdAt == createdAt &&
      other.code == code &&
      other.link == link &&
      other.note == note;

    @override
    int get hashCode =>
        id.hashCode +
        rail.hashCode +
        (inviteeName == null ? 0 : inviteeName.hashCode) +
        createdBy.hashCode +
        status.hashCode +
        opens.hashCode +
        claims.hashCode +
        paused.hashCode +
        (pausedReason == null ? 0 : pausedReason.hashCode) +
        createdAt.hashCode +
        code.hashCode +
        link.hashCode +
        (note == null ? 0 : note.hashCode);

  factory PlanInvite.fromJson(Map<String, dynamic> json) => _$PlanInviteFromJson(json);

  Map<String, dynamic> toJson() => _$PlanInviteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum PlanInviteRailEnum {
@JsonValue(r'vouch')
vouch(r'vouch'),
@JsonValue(r'public')
public(r'public');

const PlanInviteRailEnum(this.value);

final String value;

@override
String toString() => value;
}


