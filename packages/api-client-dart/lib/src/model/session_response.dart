//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/member_person.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SessionResponse {
  /// Returns a new [SessionResponse] instance.
  SessionResponse({

    required  this.user,

     this.token,
  });

  @JsonKey(
    
    name: r'user',
    required: true,
    includeIfNull: false,
  )


  final MemberPerson user;



  @JsonKey(
    
    name: r'token',
    required: false,
    includeIfNull: false,
  )


  final String? token;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SessionResponse &&
      other.user == user &&
      other.token == token;

    @override
    int get hashCode =>
        user.hashCode +
        token.hashCode;

  factory SessionResponse.fromJson(Map<String, dynamic> json) => _$SessionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SessionResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

