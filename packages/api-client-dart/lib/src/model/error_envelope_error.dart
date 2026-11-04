//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/error_code.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'error_envelope_error.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ErrorEnvelopeError {
  /// Returns a new [ErrorEnvelopeError] instance.
  ErrorEnvelopeError({

    required  this.code,

    required  this.message,

    required  this.requestId,
  });

  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final ErrorCode code;



  @JsonKey(
    
    name: r'message',
    required: true,
    includeIfNull: false,
  )


  final String message;



  @JsonKey(
    
    name: r'requestId',
    required: true,
    includeIfNull: false,
  )


  final String requestId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ErrorEnvelopeError &&
      other.code == code &&
      other.message == message &&
      other.requestId == requestId;

    @override
    int get hashCode =>
        code.hashCode +
        message.hashCode +
        requestId.hashCode;

  factory ErrorEnvelopeError.fromJson(Map<String, dynamic> json) => _$ErrorEnvelopeErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorEnvelopeErrorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

