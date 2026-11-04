//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/invite_create_one_of1.dart';
import 'package:velio_api/src/model/invite_create_one_of.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_create.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InviteCreate {
  /// Returns a new [InviteCreate] instance.
  InviteCreate({

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


  final InviteCreateRailEnum rail;



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
    bool operator ==(Object other) => identical(this, other) || other is InviteCreate &&
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

  factory InviteCreate.fromJson(Map<String, dynamic> json) => _$InviteCreateFromJson(json);

  Map<String, dynamic> toJson() => _$InviteCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum InviteCreateRailEnum {
@JsonValue(r'public')
public(r'public');

const InviteCreateRailEnum(this.value);

final String value;

@override
String toString() => value;
}


