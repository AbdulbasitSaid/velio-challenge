//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_create_one_of1.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InviteCreateOneOf1 {
  /// Returns a new [InviteCreateOneOf1] instance.
  InviteCreateOneOf1({

    required  this.rail,
  });

  @JsonKey(
    
    name: r'rail',
    required: true,
    includeIfNull: false,
  )


  final InviteCreateOneOf1RailEnum rail;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InviteCreateOneOf1 &&
      other.rail == rail;

    @override
    int get hashCode =>
        rail.hashCode;

  factory InviteCreateOneOf1.fromJson(Map<String, dynamic> json) => _$InviteCreateOneOf1FromJson(json);

  Map<String, dynamic> toJson() => _$InviteCreateOneOf1ToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum InviteCreateOneOf1RailEnum {
@JsonValue(r'public')
public(r'public');

const InviteCreateOneOf1RailEnum(this.value);

final String value;

@override
String toString() => value;
}


