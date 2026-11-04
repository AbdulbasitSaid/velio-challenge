//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/pause_reason.dart';
import 'package:velio_api/src/model/public_person.dart';
import 'package:velio_api/src/model/public_activity.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_view.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InviteView {
  /// Returns a new [InviteView] instance.
  InviteView({

    required  this.code,

    required  this.rail,

    required  this.status,

    required  this.pausedReason,

    required  this.inviter,

    required  this.note,

    required  this.claimedByViewer,

    required  this.activity,
  });

  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'rail',
    required: true,
    includeIfNull: false,
  )


  final InviteViewRailEnum rail;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final InviteViewStatusEnum status;



  @JsonKey(
    
    name: r'pausedReason',
    required: true,
    includeIfNull: true,
  )


  final PauseReason? pausedReason;



  @JsonKey(
    
    name: r'inviter',
    required: true,
    includeIfNull: false,
  )


  final PublicPerson inviter;



  @JsonKey(
    
    name: r'note',
    required: true,
    includeIfNull: true,
  )


  final String? note;



  @JsonKey(
    
    name: r'claimedByViewer',
    required: true,
    includeIfNull: false,
  )


  final bool claimedByViewer;



  @JsonKey(
    
    name: r'activity',
    required: true,
    includeIfNull: false,
  )


  final PublicActivity activity;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InviteView &&
      other.code == code &&
      other.rail == rail &&
      other.status == status &&
      other.pausedReason == pausedReason &&
      other.inviter == inviter &&
      other.note == note &&
      other.claimedByViewer == claimedByViewer &&
      other.activity == activity;

    @override
    int get hashCode =>
        code.hashCode +
        rail.hashCode +
        status.hashCode +
        (pausedReason == null ? 0 : pausedReason.hashCode) +
        inviter.hashCode +
        (note == null ? 0 : note.hashCode) +
        claimedByViewer.hashCode +
        activity.hashCode;

  factory InviteView.fromJson(Map<String, dynamic> json) => _$InviteViewFromJson(json);

  Map<String, dynamic> toJson() => _$InviteViewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum InviteViewRailEnum {
@JsonValue(r'vouch')
vouch(r'vouch'),
@JsonValue(r'public')
public(r'public');

const InviteViewRailEnum(this.value);

final String value;

@override
String toString() => value;
}


enum InviteViewStatusEnum {
@JsonValue(r'claimable')
claimable(r'claimable'),
@JsonValue(r'claimed')
claimed(r'claimed'),
@JsonValue(r'expired')
expired(r'expired'),
@JsonValue(r'paused')
paused(r'paused');

const InviteViewStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


