//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/host_activity_item.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'host_activity_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class HostActivityList {
  /// Returns a new [HostActivityList] instance.
  HostActivityList({

    required  this.upcoming,

    required  this.past,
  });

  @JsonKey(
    
    name: r'upcoming',
    required: true,
    includeIfNull: false,
  )


  final List<HostActivityItem> upcoming;



  @JsonKey(
    
    name: r'past',
    required: true,
    includeIfNull: false,
  )


  final List<HostActivityItem> past;





    @override
    bool operator ==(Object other) => identical(this, other) || other is HostActivityList &&
      other.upcoming == upcoming &&
      other.past == past;

    @override
    int get hashCode =>
        upcoming.hashCode +
        past.hashCode;

  factory HostActivityList.fromJson(Map<String, dynamic> json) => _$HostActivityListFromJson(json);

  Map<String, dynamic> toJson() => _$HostActivityListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

