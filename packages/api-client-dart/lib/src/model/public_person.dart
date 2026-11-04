//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_person.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicPerson {
  /// Returns a new [PublicPerson] instance.
  PublicPerson({

    required  this.id,

    required  this.shortName,

    required  this.avatarSeed,
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





    @override
    bool operator ==(Object other) => identical(this, other) || other is PublicPerson &&
      other.id == id &&
      other.shortName == shortName &&
      other.avatarSeed == avatarSeed;

    @override
    int get hashCode =>
        id.hashCode +
        shortName.hashCode +
        avatarSeed.hashCode;

  factory PublicPerson.fromJson(Map<String, dynamic> json) => _$PublicPersonFromJson(json);

  Map<String, dynamic> toJson() => _$PublicPersonToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

