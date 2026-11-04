//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/activity_card.dart';
import 'package:velio_api/src/model/community.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'community_page.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CommunityPage {
  /// Returns a new [CommunityPage] instance.
  CommunityPage({

    required  this.community,

    required  this.activities,
  });

  @JsonKey(
    
    name: r'community',
    required: true,
    includeIfNull: false,
  )


  final Community community;



  @JsonKey(
    
    name: r'activities',
    required: true,
    includeIfNull: false,
  )


  final List<ActivityCard> activities;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CommunityPage &&
      other.community == community &&
      other.activities == activities;

    @override
    int get hashCode =>
        community.hashCode +
        activities.hashCode;

  factory CommunityPage.fromJson(Map<String, dynamic> json) => _$CommunityPageFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

