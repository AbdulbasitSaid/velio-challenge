//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/activity_card.dart';
import 'package:velio_api/src/model/public_person.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'profile.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Profile {
  /// Returns a new [Profile] instance.
  Profile({

    required  this.person,

    required  this.memberSince,

    required  this.hosting,
  });

  @JsonKey(
    
    name: r'person',
    required: true,
    includeIfNull: false,
  )


  final PublicPerson person;



  @JsonKey(
    
    name: r'memberSince',
    required: true,
    includeIfNull: false,
  )


  final String memberSince;



  @JsonKey(
    
    name: r'hosting',
    required: true,
    includeIfNull: false,
  )


  final List<ActivityCard> hosting;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Profile &&
      other.person == person &&
      other.memberSince == memberSince &&
      other.hosting == hosting;

    @override
    int get hashCode =>
        person.hashCode +
        memberSince.hashCode +
        hosting.hashCode;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

