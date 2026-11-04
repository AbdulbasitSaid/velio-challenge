//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/invite_status.dart';
import 'package:velio_api/src/model/pause_reason.dart';
import 'package:velio_api/src/model/member_person.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Invite {
  /// Returns a new [Invite] instance.
  Invite({

    required  this.id,

    required  this.code,

    required  this.link,

    required  this.rail,

    required  this.inviteeName,

    required  this.note,

    required  this.status,

    required  this.opens,

    required  this.claims,

    required  this.paused,

    required  this.pausedReason,

    required  this.createdBy,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;



  @JsonKey(
    
    name: r'rail',
    required: true,
    includeIfNull: false,
  )


  final InviteRailEnum rail;



  @JsonKey(
    
    name: r'inviteeName',
    required: true,
    includeIfNull: true,
  )


  final String? inviteeName;



  @JsonKey(
    
    name: r'note',
    required: true,
    includeIfNull: true,
  )


  final String? note;



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
    
    name: r'createdBy',
    required: true,
    includeIfNull: false,
  )


  final MemberPerson createdBy;



  @JsonKey(
    
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Invite &&
      other.id == id &&
      other.code == code &&
      other.link == link &&
      other.rail == rail &&
      other.inviteeName == inviteeName &&
      other.note == note &&
      other.status == status &&
      other.opens == opens &&
      other.claims == claims &&
      other.paused == paused &&
      other.pausedReason == pausedReason &&
      other.createdBy == createdBy &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        code.hashCode +
        link.hashCode +
        rail.hashCode +
        (inviteeName == null ? 0 : inviteeName.hashCode) +
        (note == null ? 0 : note.hashCode) +
        status.hashCode +
        opens.hashCode +
        claims.hashCode +
        paused.hashCode +
        (pausedReason == null ? 0 : pausedReason.hashCode) +
        createdBy.hashCode +
        createdAt.hashCode;

  factory Invite.fromJson(Map<String, dynamic> json) => _$InviteFromJson(json);

  Map<String, dynamic> toJson() => _$InviteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum InviteRailEnum {
@JsonValue(r'vouch')
vouch(r'vouch'),
@JsonValue(r'public')
public(r'public');

const InviteRailEnum(this.value);

final String value;

@override
String toString() => value;
}


