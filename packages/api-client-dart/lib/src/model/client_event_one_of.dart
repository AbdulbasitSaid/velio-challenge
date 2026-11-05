//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'client_event_one_of.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ClientEventOneOf {
  /// Returns a new [ClientEventOneOf] instance.
  ClientEventOneOf({

    required  this.name,

    required  this.activityId,

     this.platform,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final ClientEventOneOfNameEnum name;



  @JsonKey(
    
    name: r'activityId',
    required: true,
    includeIfNull: false,
  )


  final String activityId;



  @JsonKey(
    
    name: r'platform',
    required: false,
    includeIfNull: false,
  )


  final ClientEventOneOfPlatformEnum? platform;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ClientEventOneOf &&
      other.name == name &&
      other.activityId == activityId &&
      other.platform == platform;

    @override
    int get hashCode =>
        name.hashCode +
        activityId.hashCode +
        platform.hashCode;

  factory ClientEventOneOf.fromJson(Map<String, dynamic> json) => _$ClientEventOneOfFromJson(json);

  Map<String, dynamic> toJson() => _$ClientEventOneOfToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum ClientEventOneOfNameEnum {
@JsonValue(r'activity_viewed')
activityViewed(r'activity_viewed');

const ClientEventOneOfNameEnum(this.value);

final String value;

@override
String toString() => value;
}


enum ClientEventOneOfPlatformEnum {
@JsonValue(r'web')
web(r'web'),
@JsonValue(r'ios')
ios(r'ios'),
@JsonValue(r'android')
android(r'android');

const ClientEventOneOfPlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


