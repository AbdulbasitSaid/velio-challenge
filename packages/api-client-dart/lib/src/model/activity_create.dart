//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/location.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity_create.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActivityCreate {
  /// Returns a new [ActivityCreate] instance.
  ActivityCreate({

    required  this.communitySlug,

    required  this.title,

     this.description,

    required  this.startsAt,

    required  this.timezone,

    required  this.location,

    required  this.priceMinor,

    required  this.currency,

    required  this.capacity,

     this.photoKey,
  });

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
    required: false,
    includeIfNull: false,
  )


  final String? description;



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



          // minimum: 0
          // maximum: 9007199254740991
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



          // minimum: 1
          // maximum: 100000
  @JsonKey(
    
    name: r'capacity',
    required: true,
    includeIfNull: false,
  )


  final int capacity;



  @JsonKey(
    
    name: r'photoKey',
    required: false,
    includeIfNull: false,
  )


  final String? photoKey;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ActivityCreate &&
      other.communitySlug == communitySlug &&
      other.title == title &&
      other.description == description &&
      other.startsAt == startsAt &&
      other.timezone == timezone &&
      other.location == location &&
      other.priceMinor == priceMinor &&
      other.currency == currency &&
      other.capacity == capacity &&
      other.photoKey == photoKey;

    @override
    int get hashCode =>
        communitySlug.hashCode +
        title.hashCode +
        description.hashCode +
        startsAt.hashCode +
        timezone.hashCode +
        location.hashCode +
        priceMinor.hashCode +
        currency.hashCode +
        capacity.hashCode +
        (photoKey == null ? 0 : photoKey.hashCode);

  factory ActivityCreate.fromJson(Map<String, dynamic> json) => _$ActivityCreateFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

