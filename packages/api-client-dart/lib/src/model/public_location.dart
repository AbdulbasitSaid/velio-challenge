//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_location.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicLocation {
  /// Returns a new [PublicLocation] instance.
  PublicLocation({

    required  this.placeId,

    required  this.venueName,

    required  this.addressText,

    required  this.lat,

    required  this.lng,

    required  this.meetingPoint,

    required  this.staticMapUrl,

    required  this.directionsUrl,
  });

  @JsonKey(
    
    name: r'placeId',
    required: true,
    includeIfNull: true,
  )


  final String? placeId;



  @JsonKey(
    
    name: r'venueName',
    required: true,
    includeIfNull: false,
  )


  final String venueName;



  @JsonKey(
    
    name: r'addressText',
    required: true,
    includeIfNull: false,
  )


  final String addressText;



          // minimum: -90
          // maximum: 90
  @JsonKey(
    
    name: r'lat',
    required: true,
    includeIfNull: false,
  )


  final num lat;



          // minimum: -180
          // maximum: 180
  @JsonKey(
    
    name: r'lng',
    required: true,
    includeIfNull: false,
  )


  final num lng;



  @JsonKey(
    
    name: r'meetingPoint',
    required: true,
    includeIfNull: true,
  )


  final String? meetingPoint;



  @JsonKey(
    
    name: r'staticMapUrl',
    required: true,
    includeIfNull: true,
  )


  final String? staticMapUrl;



  @JsonKey(
    
    name: r'directionsUrl',
    required: true,
    includeIfNull: false,
  )


  final String directionsUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PublicLocation &&
      other.placeId == placeId &&
      other.venueName == venueName &&
      other.addressText == addressText &&
      other.lat == lat &&
      other.lng == lng &&
      other.meetingPoint == meetingPoint &&
      other.staticMapUrl == staticMapUrl &&
      other.directionsUrl == directionsUrl;

    @override
    int get hashCode =>
        (placeId == null ? 0 : placeId.hashCode) +
        venueName.hashCode +
        addressText.hashCode +
        lat.hashCode +
        lng.hashCode +
        (meetingPoint == null ? 0 : meetingPoint.hashCode) +
        (staticMapUrl == null ? 0 : staticMapUrl.hashCode) +
        directionsUrl.hashCode;

  factory PublicLocation.fromJson(Map<String, dynamic> json) => _$PublicLocationFromJson(json);

  Map<String, dynamic> toJson() => _$PublicLocationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

