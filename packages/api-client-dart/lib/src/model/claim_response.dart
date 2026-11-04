//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/member_person.dart';
import 'package:velio_api/src/model/booking.dart';
import 'package:velio_api/src/model/activity_state.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'claim_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClaimResponse {
  /// Returns a new [ClaimResponse] instance.
  ClaimResponse({

    required  this.booking,

    required  this.activity,

    required  this.planId,

    required  this.user,

     this.token,
  });

  @JsonKey(
    
    name: r'booking',
    required: true,
    includeIfNull: false,
  )


  final Booking booking;



  @JsonKey(
    
    name: r'activity',
    required: true,
    includeIfNull: false,
  )


  final ActivityState activity;



  @JsonKey(
    
    name: r'planId',
    required: true,
    includeIfNull: false,
  )


  final String planId;



  @JsonKey(
    
    name: r'user',
    required: true,
    includeIfNull: false,
  )


  final MemberPerson user;



  @JsonKey(
    
    name: r'token',
    required: false,
    includeIfNull: false,
  )


  final String? token;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ClaimResponse &&
      other.booking == booking &&
      other.activity == activity &&
      other.planId == planId &&
      other.user == user &&
      other.token == token;

    @override
    int get hashCode =>
        booking.hashCode +
        activity.hashCode +
        planId.hashCode +
        user.hashCode +
        token.hashCode;

  factory ClaimResponse.fromJson(Map<String, dynamic> json) => _$ClaimResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

