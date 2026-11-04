//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'open_create.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OpenCreate {
  /// Returns a new [OpenCreate] instance.
  OpenCreate({

     this.platform,
  });

  @JsonKey(
    
    name: r'platform',
    required: false,
    includeIfNull: false,
  )


  final OpenCreatePlatformEnum? platform;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OpenCreate &&
      other.platform == platform;

    @override
    int get hashCode =>
        platform.hashCode;

  factory OpenCreate.fromJson(Map<String, dynamic> json) => _$OpenCreateFromJson(json);

  Map<String, dynamic> toJson() => _$OpenCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum OpenCreatePlatformEnum {
@JsonValue(r'web')
web(r'web'),
@JsonValue(r'ios')
ios(r'ios'),
@JsonValue(r'android')
android(r'android');

const OpenCreatePlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


