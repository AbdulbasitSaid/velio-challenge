//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_create_one_of.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InviteCreateOneOf {
  /// Returns a new [InviteCreateOneOf] instance.
  InviteCreateOneOf({

    required  this.rail,

    required  this.inviteeName,

     this.contact,

     this.country,

     this.note,
  });

  @JsonKey(
    
    name: r'rail',
    required: true,
    includeIfNull: false,
  )


  final InviteCreateOneOfRailEnum rail;



  @JsonKey(
    
    name: r'inviteeName',
    required: true,
    includeIfNull: false,
  )


  final String inviteeName;



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
    
    name: r'note',
    required: false,
    includeIfNull: false,
  )


  final String? note;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InviteCreateOneOf &&
      other.rail == rail &&
      other.inviteeName == inviteeName &&
      other.contact == contact &&
      other.country == country &&
      other.note == note;

    @override
    int get hashCode =>
        rail.hashCode +
        inviteeName.hashCode +
        contact.hashCode +
        country.hashCode +
        note.hashCode;

  factory InviteCreateOneOf.fromJson(Map<String, dynamic> json) => _$InviteCreateOneOfFromJson(json);

  Map<String, dynamic> toJson() => _$InviteCreateOneOfToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum InviteCreateOneOfRailEnum {
@JsonValue(r'vouch')
vouch(r'vouch');

const InviteCreateOneOfRailEnum(this.value);

final String value;

@override
String toString() => value;
}


