//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/public_activity_members.dart';
import 'package:velio_api/src/model/public_activity_viewer.dart';
import 'package:velio_api/src/model/public_activity_community.dart';
import 'package:velio_api/src/model/public_person.dart';
import 'package:velio_api/src/model/public_location.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_activity.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicActivity {
  /// Returns a new [PublicActivity] instance.
  PublicActivity({

    required  this.id,

    required  this.title,

    required  this.description,

    required  this.photoUrl,

    required  this.startsAt,

    required  this.timezone,

    required  this.priceMinor,

    required  this.currency,

    required  this.capacity,

    required  this.spotsLeft,

    required  this.version,

    required  this.status,

    required  this.bookingsPaused,

    required  this.host,

    required  this.community,

    required  this.members,

    required  this.location,

    required  this.viewer,
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
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



  @JsonKey(
    
    name: r'photoUrl',
    required: true,
    includeIfNull: true,
  )


  final String? photoUrl;



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


  final PublicActivityStatusEnum status;



  @JsonKey(
    
    name: r'bookingsPaused',
    required: true,
    includeIfNull: false,
  )


  final bool bookingsPaused;



  @JsonKey(
    
    name: r'host',
    required: true,
    includeIfNull: false,
  )


  final PublicPerson host;



  @JsonKey(
    
    name: r'community',
    required: true,
    includeIfNull: false,
  )


  final PublicActivityCommunity community;



  @JsonKey(
    
    name: r'members',
    required: true,
    includeIfNull: false,
  )


  final PublicActivityMembers members;



  @JsonKey(
    
    name: r'location',
    required: true,
    includeIfNull: false,
  )


  final PublicLocation location;



  @JsonKey(
    
    name: r'viewer',
    required: true,
    includeIfNull: true,
  )


  final PublicActivityViewer? viewer;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PublicActivity &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.photoUrl == photoUrl &&
      other.startsAt == startsAt &&
      other.timezone == timezone &&
      other.priceMinor == priceMinor &&
      other.currency == currency &&
      other.capacity == capacity &&
      other.spotsLeft == spotsLeft &&
      other.version == version &&
      other.status == status &&
      other.bookingsPaused == bookingsPaused &&
      other.host == host &&
      other.community == community &&
      other.members == members &&
      other.location == location &&
      other.viewer == viewer;

    @override
    int get hashCode =>
        id.hashCode +
        title.hashCode +
        description.hashCode +
        (photoUrl == null ? 0 : photoUrl.hashCode) +
        startsAt.hashCode +
        timezone.hashCode +
        priceMinor.hashCode +
        currency.hashCode +
        capacity.hashCode +
        spotsLeft.hashCode +
        version.hashCode +
        status.hashCode +
        bookingsPaused.hashCode +
        host.hashCode +
        community.hashCode +
        members.hashCode +
        location.hashCode +
        (viewer == null ? 0 : viewer.hashCode);

  factory PublicActivity.fromJson(Map<String, dynamic> json) => _$PublicActivityFromJson(json);

  Map<String, dynamic> toJson() => _$PublicActivityToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum PublicActivityStatusEnum {
@JsonValue(r'open')
open(r'open'),
@JsonValue(r'sold_out')
soldOut(r'sold_out'),
@JsonValue(r'started')
started(r'started');

const PublicActivityStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


