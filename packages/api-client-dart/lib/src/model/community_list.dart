//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/community.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'community_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CommunityList {
  /// Returns a new [CommunityList] instance.
  CommunityList({

    required  this.communities,
  });

  @JsonKey(
    
    name: r'communities',
    required: true,
    includeIfNull: false,
  )


  final List<Community> communities;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CommunityList &&
      other.communities == communities;

    @override
    int get hashCode =>
        communities.hashCode;

  factory CommunityList.fromJson(Map<String, dynamic> json) => _$CommunityListFromJson(json);

  Map<String, dynamic> toJson() => _$CommunityListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

