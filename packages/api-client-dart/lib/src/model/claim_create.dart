//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'claim_create.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClaimCreate {
  /// Returns a new [ClaimCreate] instance.
  ClaimCreate({

     this.displayName,

     this.contact,

     this.country,

     this.platform,
  });

  @JsonKey(
    
    name: r'displayName',
    required: false,
    includeIfNull: false,
  )


  final String? displayName;



  @JsonKey(
    
    name: r'contact',
    required: false,
    includeIfNull: false,
  )


  final String? contact;



  @JsonKey(
    
    name: r'country',
    required: false,
    includeIfNull: false,
  )


  final String? country;



  @JsonKey(
    
    name: r'platform',
    required: false,
    includeIfNull: false,
  )


  final ClaimCreatePlatformEnum? platform;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ClaimCreate &&
      other.displayName == displayName &&
      other.contact == contact &&
      other.country == country &&
      other.platform == platform;

    @override
    int get hashCode =>
        displayName.hashCode +
        contact.hashCode +
        country.hashCode +
        platform.hashCode;

  factory ClaimCreate.fromJson(Map<String, dynamic> json) => _$ClaimCreateFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum ClaimCreatePlatformEnum {
@JsonValue(r'web')
web(r'web'),
@JsonValue(r'ios')
ios(r'ios'),
@JsonValue(r'android')
android(r'android');

const ClaimCreatePlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


