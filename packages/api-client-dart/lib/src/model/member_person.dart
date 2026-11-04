//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'member_person.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MemberPerson {
  /// Returns a new [MemberPerson] instance.
  MemberPerson({

    required  this.id,

    required  this.shortName,

    required  this.avatarSeed,

    required  this.displayName,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'shortName',
    required: true,
    includeIfNull: false,
  )


  final String shortName;



  @JsonKey(
    
    name: r'avatarSeed',
    required: true,
    includeIfNull: false,
  )


  final String avatarSeed;



  @JsonKey(
    
    name: r'displayName',
    required: true,
    includeIfNull: false,
  )


  final String displayName;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MemberPerson &&
      other.id == id &&
      other.shortName == shortName &&
      other.avatarSeed == avatarSeed &&
      other.displayName == displayName;

    @override
    int get hashCode =>
        id.hashCode +
        shortName.hashCode +
        avatarSeed.hashCode +
        displayName.hashCode;

  factory MemberPerson.fromJson(Map<String, dynamic> json) => _$MemberPersonFromJson(json);

  Map<String, dynamic> toJson() => _$MemberPersonToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

