//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Location {
  /// Returns a new [Location] instance.
  Location({

     this.placeId,

    required  this.venueName,

    required  this.addressText,

    required  this.lat,

    required  this.lng,

     this.meetingPoint,
  });

  @JsonKey(
    
    name: r'placeId',
    required: false,
    includeIfNull: false,
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
    required: false,
    includeIfNull: false,
  )


  final String? meetingPoint;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Location &&
      other.placeId == placeId &&
      other.venueName == venueName &&
      other.addressText == addressText &&
      other.lat == lat &&
      other.lng == lng &&
      other.meetingPoint == meetingPoint;

    @override
    int get hashCode =>
        (placeId == null ? 0 : placeId.hashCode) +
        venueName.hashCode +
        addressText.hashCode +
        lat.hashCode +
        lng.hashCode +
        (meetingPoint == null ? 0 : meetingPoint.hashCode);

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

