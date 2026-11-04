//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity_card_location.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActivityCardLocation {
  /// Returns a new [ActivityCardLocation] instance.
  ActivityCardLocation({

    required  this.venueName,

    required  this.lat,

    required  this.lng,
  });

  @JsonKey(
    
    name: r'venueName',
    required: true,
    includeIfNull: false,
  )


  final String venueName;



  @JsonKey(
    
    name: r'lat',
    required: true,
    includeIfNull: false,
  )


  final num lat;



  @JsonKey(
    
    name: r'lng',
    required: true,
    includeIfNull: false,
  )


  final num lng;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ActivityCardLocation &&
      other.venueName == venueName &&
      other.lat == lat &&
      other.lng == lng;

    @override
    int get hashCode =>
        venueName.hashCode +
        lat.hashCode +
        lng.hashCode;

  factory ActivityCardLocation.fromJson(Map<String, dynamic> json) => _$ActivityCardLocationFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityCardLocationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

