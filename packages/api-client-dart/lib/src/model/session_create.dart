//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session_create.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SessionCreate {
  /// Returns a new [SessionCreate] instance.
  SessionCreate({

    required  this.displayName,

    required  this.contact,

     this.country,
  });

  @JsonKey(
    
    name: r'displayName',
    required: true,
    includeIfNull: false,
  )


  final String displayName;



  @JsonKey(
    
    name: r'contact',
    required: true,
    includeIfNull: false,
  )


  final String contact;



  @JsonKey(
    
    name: r'country',
    required: false,
    includeIfNull: false,
  )


  final String? country;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SessionCreate &&
      other.displayName == displayName &&
      other.contact == contact &&
      other.country == country;

    @override
    int get hashCode =>
        displayName.hashCode +
        contact.hashCode +
        country.hashCode;

  factory SessionCreate.fromJson(Map<String, dynamic> json) => _$SessionCreateFromJson(json);

  Map<String, dynamic> toJson() => _$SessionCreateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

