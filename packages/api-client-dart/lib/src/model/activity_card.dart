//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/activity_card_location.dart';
import 'package:velio_api/src/model/public_activity_members.dart';
import 'package:velio_api/src/model/public_activity_community.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity_card.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActivityCard {
  /// Returns a new [ActivityCard] instance.
  ActivityCard({

    required  this.id,

    required  this.title,

    required  this.startsAt,

    required  this.timezone,

    required  this.priceMinor,

    required  this.currency,

    required  this.photoUrl,

    required  this.capacity,

    required  this.spotsLeft,

    required  this.version,

    required  this.status,

    required  this.community,

    required  this.location,

    required  this.members,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'startsAt',
    required: true,
    includeIfNull: false,
  )


  final DateTime startsAt;



  @JsonKey(
    
    name: r'timezone',
    required: true,
    includeIfNull: false,
  )


  final String timezone;



  @JsonKey(
    
    name: r'priceMinor',
    required: true,
    includeIfNull: false,
  )


  final int priceMinor;



  @JsonKey(
    
    name: r'currency',
    required: true,
    includeIfNull: false,
  )


  final String currency;



  @JsonKey(
    
    name: r'photoUrl',
    required: true,
    includeIfNull: true,
  )


  final String? photoUrl;



  @JsonKey(
    
    name: r'capacity',
    required: true,
    includeIfNull: false,
  )


  final int capacity;



  @JsonKey(
    
    name: r'spotsLeft',
    required: true,
    includeIfNull: false,
  )


  final int spotsLeft;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final ActivityCardStatusEnum status;



  @JsonKey(
    
    name: r'community',
    required: true,
    includeIfNull: false,
  )


  final PublicActivityCommunity community;



  @JsonKey(
    
    name: r'location',
    required: true,
    includeIfNull: false,
  )


  final ActivityCardLocation location;



  @JsonKey(
    
    name: r'members',
    required: true,
    includeIfNull: false,
  )


  final PublicActivityMembers members;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ActivityCard &&
      other.id == id &&
      other.title == title &&
      other.startsAt == startsAt &&
      other.timezone == timezone &&
      other.priceMinor == priceMinor &&
      other.currency == currency &&
      other.photoUrl == photoUrl &&
      other.capacity == capacity &&
      other.spotsLeft == spotsLeft &&
      other.version == version &&
      other.status == status &&
      other.community == community &&
      other.location == location &&
      other.members == members;

    @override
    int get hashCode =>
        id.hashCode +
        title.hashCode +
        startsAt.hashCode +
        timezone.hashCode +
        priceMinor.hashCode +
        currency.hashCode +
        (photoUrl == null ? 0 : photoUrl.hashCode) +
        capacity.hashCode +
        spotsLeft.hashCode +
        version.hashCode +
        status.hashCode +
        community.hashCode +
        location.hashCode +
        members.hashCode;

  factory ActivityCard.fromJson(Map<String, dynamic> json) => _$ActivityCardFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityCardToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum ActivityCardStatusEnum {
@JsonValue(r'open')
open(r'open'),
@JsonValue(r'sold_out')
soldOut(r'sold_out'),
@JsonValue(r'started')
started(r'started');

const ActivityCardStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


