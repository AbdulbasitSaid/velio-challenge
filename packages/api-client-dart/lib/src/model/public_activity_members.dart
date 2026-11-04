//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/public_person.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_activity_members.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicActivityMembers {
  /// Returns a new [PublicActivityMembers] instance.
  PublicActivityMembers({

    required  this.count,

    required  this.preview,
  });

  @JsonKey(
    
    name: r'count',
    required: true,
    includeIfNull: false,
  )


  final int count;



  @JsonKey(
    
    name: r'preview',
    required: true,
    includeIfNull: false,
  )


  final List<PublicPerson> preview;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PublicActivityMembers &&
      other.count == count &&
      other.preview == preview;

    @override
    int get hashCode =>
        count.hashCode +
        preview.hashCode;

  factory PublicActivityMembers.fromJson(Map<String, dynamic> json) => _$PublicActivityMembersFromJson(json);

  Map<String, dynamic> toJson() => _$PublicActivityMembersToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

