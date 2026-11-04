//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/location.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'host_activity.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HostActivity {
  /// Returns a new [HostActivity] instance.
  HostActivity({

    required  this.id,

    required  this.hostId,

    required  this.communitySlug,

    required  this.title,

    required  this.description,

    required  this.startsAt,

    required  this.timezone,

    required  this.location,

    required  this.priceMinor,

    required  this.currency,

    required  this.capacity,

    required  this.spotsLeft,

    required  this.bookedCount,

    required  this.version,

    required  this.bookingsPaused,

    required  this.photoKey,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'hostId',
    required: true,
    includeIfNull: false,
  )


  final String hostId;



  @JsonKey(
    
    name: r'communitySlug',
    required: true,
    includeIfNull: false,
  )


  final String communitySlug;



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
    
    name: r'location',
    required: true,
    includeIfNull: false,
  )


  final Location location;



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
    
    name: r'bookedCount',
    required: true,
    includeIfNull: false,
  )


  final int bookedCount;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;



  @JsonKey(
    
    name: r'bookingsPaused',
    required: true,
    includeIfNull: false,
  )


  final bool bookingsPaused;



  @JsonKey(
    
    name: r'photoKey',
    required: true,
    includeIfNull: true,
  )


  final String? photoKey;



  @JsonKey(
    
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is HostActivity &&
      other.id == id &&
      other.hostId == hostId &&
      other.communitySlug == communitySlug &&
      other.title == title &&
      other.description == description &&
      other.startsAt == startsAt &&
      other.timezone == timezone &&
      other.location == location &&
      other.priceMinor == priceMinor &&
      other.currency == currency &&
      other.capacity == capacity &&
      other.spotsLeft == spotsLeft &&
      other.bookedCount == bookedCount &&
      other.version == version &&
      other.bookingsPaused == bookingsPaused &&
      other.photoKey == photoKey &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        hostId.hashCode +
        communitySlug.hashCode +
        title.hashCode +
        description.hashCode +
        startsAt.hashCode +
        timezone.hashCode +
        location.hashCode +
        priceMinor.hashCode +
        currency.hashCode +
        capacity.hashCode +
        spotsLeft.hashCode +
        bookedCount.hashCode +
        version.hashCode +
        bookingsPaused.hashCode +
        (photoKey == null ? 0 : photoKey.hashCode) +
        createdAt.hashCode;

  factory HostActivity.fromJson(Map<String, dynamic> json) => _$HostActivityFromJson(json);

  Map<String, dynamic> toJson() => _$HostActivityToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

