//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/presigned_post.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'photo_upload_response_uploads.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PhotoUploadResponseUploads {
  /// Returns a new [PhotoUploadResponseUploads] instance.
  PhotoUploadResponseUploads({

    required  this.large,

    required  this.small,
  });

  @JsonKey(
    
    name: r'large',
    required: true,
    includeIfNull: false,
  )


  final PresignedPost large;



  @JsonKey(
    
    name: r'small',
    required: true,
    includeIfNull: false,
  )


  final PresignedPost small;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PhotoUploadResponseUploads &&
      other.large == large &&
      other.small == small;

    @override
    int get hashCode =>
        large.hashCode +
        small.hashCode;

  factory PhotoUploadResponseUploads.fromJson(Map<String, dynamic> json) => _$PhotoUploadResponseUploadsFromJson(json);

  Map<String, dynamic> toJson() => _$PhotoUploadResponseUploadsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

