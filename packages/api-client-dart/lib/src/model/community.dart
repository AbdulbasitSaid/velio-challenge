//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'community.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Community {
  /// Returns a new [Community] instance.
  Community({

    required  this.slug,

    required  this.name,

    required  this.blurb,

    required  this.coverPhotoUrl,

    required  this.upcomingCount,
  });

  @JsonKey(
    
    name: r'slug',
    required: true,
    includeIfNull: false,
  )


  final String slug;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'blurb',
    required: true,
    includeIfNull: false,
  )


  final String blurb;



  @JsonKey(
    
    name: r'coverPhotoUrl',
    required: true,
    includeIfNull: true,
  )


  final String? coverPhotoUrl;



  @JsonKey(
    
    name: r'upcomingCount',
    required: true,
    includeIfNull: false,
  )


  final int upcomingCount;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Community &&
      other.slug == slug &&
      other.name == name &&
      other.blurb == blurb &&
      other.coverPhotoUrl == coverPhotoUrl &&
      other.upcomingCount == upcomingCount;

    @override
    int get hashCode =>
        slug.hashCode +
        name.hashCode +
        blurb.hashCode +
        (coverPhotoUrl == null ? 0 : coverPhotoUrl.hashCode) +
        upcomingCount.hashCode;

  factory Community.fromJson(Map<String, dynamic> json) => _$CommunityFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

