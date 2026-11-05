//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/activity_card_location.dart';
import 'package:velio_api/src/model/public_activity_members.dart';
import 'package:velio_api/src/model/public_activity_community.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'host_activity_item.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HostActivityItem {
  /// Returns a new [HostActivityItem] instance.
  HostActivityItem({

    required  this.id,

    required  this.title,

    required  this.summary,

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

    required  this.bookedCount,

    required  this.markedCount,

    required  this.attendedCount,
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
    
    name: r'summary',
    required: true,
    includeIfNull: false,
  )


  final String summary;



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


  final HostActivityItemStatusEnum status;



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



  @JsonKey(
    
    name: r'bookedCount',
    required: true,
    includeIfNull: false,
  )


  final int bookedCount;



  @JsonKey(
    
    name: r'markedCount',
    required: true,
    includeIfNull: false,
  )


  final int markedCount;



  @JsonKey(
    
    name: r'attendedCount',
    required: true,
    includeIfNull: false,
  )


  final int attendedCount;





    @override
    bool operator ==(Object other) => identical(this, other) || other is HostActivityItem &&
      other.id == id &&
      other.title == title &&
      other.summary == summary &&
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
      other.members == members &&
      other.bookedCount == bookedCount &&
      other.markedCount == markedCount &&
      other.attendedCount == attendedCount;

    @override
    int get hashCode =>
        id.hashCode +
        title.hashCode +
        summary.hashCode +
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
        members.hashCode +
        bookedCount.hashCode +
        markedCount.hashCode +
        attendedCount.hashCode;

  factory HostActivityItem.fromJson(Map<String, dynamic> json) => _$HostActivityItemFromJson(json);

  Map<String, dynamic> toJson() => _$HostActivityItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum HostActivityItemStatusEnum {
@JsonValue(r'open')
open(r'open'),
@JsonValue(r'sold_out')
soldOut(r'sold_out'),
@JsonValue(r'started')
started(r'started');

const HostActivityItemStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


