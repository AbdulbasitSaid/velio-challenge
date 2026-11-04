//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/location.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity_patch.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActivityPatch {
  /// Returns a new [ActivityPatch] instance.
  ActivityPatch({

     this.title,

     this.description,

     this.startsAt,

     this.timezone,

     this.location,

     this.capacity,

     this.photoKey,
  });

  @JsonKey(
    
    name: r'title',
    required: false,
    includeIfNull: false,
  )


  final String? title;



  @JsonKey(
    
    name: r'description',
    required: false,
    includeIfNull: false,
  )


  final String? description;



  @JsonKey(
    
    name: r'startsAt',
    required: false,
    includeIfNull: false,
  )


  final DateTime? startsAt;



  @JsonKey(
    
    name: r'timezone',
    required: false,
    includeIfNull: false,
  )


  final String? timezone;



  @JsonKey(
    
    name: r'location',
    required: false,
    includeIfNull: false,
  )


  final Location? location;



          // minimum: 1
          // maximum: 100000
  @JsonKey(
    
    name: r'capacity',
    required: false,
    includeIfNull: false,
  )


  final int? capacity;



  @JsonKey(
    
    name: r'photoKey',
    required: false,
    includeIfNull: false,
  )


  final String? photoKey;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ActivityPatch &&
      other.title == title &&
      other.description == description &&
      other.startsAt == startsAt &&
      other.timezone == timezone &&
      other.location == location &&
      other.capacity == capacity &&
      other.photoKey == photoKey;

    @override
    int get hashCode =>
        title.hashCode +
        description.hashCode +
        startsAt.hashCode +
        timezone.hashCode +
        location.hashCode +
        capacity.hashCode +
        (photoKey == null ? 0 : photoKey.hashCode);

  factory ActivityPatch.fromJson(Map<String, dynamic> json) => _$ActivityPatchFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityPatchToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

