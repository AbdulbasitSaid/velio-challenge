//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/photo_upload_response_uploads.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'photo_upload_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PhotoUploadResponse {
  /// Returns a new [PhotoUploadResponse] instance.
  PhotoUploadResponse({

    required  this.key,

    required  this.uploads,

    required  this.expiresAt,
  });

  @JsonKey(
    
    name: r'key',
    required: true,
    includeIfNull: true,
  )


  final String? key;



  @JsonKey(
    
    name: r'uploads',
    required: true,
    includeIfNull: false,
  )


  final PhotoUploadResponseUploads uploads;



  @JsonKey(
    
    name: r'expiresAt',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PhotoUploadResponse &&
      other.key == key &&
      other.uploads == uploads &&
      other.expiresAt == expiresAt;

    @override
    int get hashCode =>
        (key == null ? 0 : key.hashCode) +
        uploads.hashCode +
        expiresAt.hashCode;

  factory PhotoUploadResponse.fromJson(Map<String, dynamic> json) => _$PhotoUploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PhotoUploadResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

