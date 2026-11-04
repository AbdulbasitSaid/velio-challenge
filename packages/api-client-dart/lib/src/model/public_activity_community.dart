//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_activity_community.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicActivityCommunity {
  /// Returns a new [PublicActivityCommunity] instance.
  PublicActivityCommunity({

    required  this.slug,

    required  this.name,
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





    @override
    bool operator ==(Object other) => identical(this, other) || other is PublicActivityCommunity &&
      other.slug == slug &&
      other.name == name;

    @override
    int get hashCode =>
        slug.hashCode +
        name.hashCode;

  factory PublicActivityCommunity.fromJson(Map<String, dynamic> json) => _$PublicActivityCommunityFromJson(json);

  Map<String, dynamic> toJson() => _$PublicActivityCommunityToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

