//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'photo_upload_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PhotoUploadRequest {
  /// Returns a new [PhotoUploadRequest] instance.
  PhotoUploadRequest({

    required  this.contentType,
  });

  @JsonKey(
    
    name: r'contentType',
    required: true,
    includeIfNull: false,
  )


  final PhotoUploadRequestContentTypeEnum contentType;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PhotoUploadRequest &&
      other.contentType == contentType;

    @override
    int get hashCode =>
        contentType.hashCode;

  factory PhotoUploadRequest.fromJson(Map<String, dynamic> json) => _$PhotoUploadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PhotoUploadRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum PhotoUploadRequestContentTypeEnum {
@JsonValue(r'image/webp')
imageSlashWebp(r'image/webp'),
@JsonValue(r'image/jpeg')
imageSlashJpeg(r'image/jpeg'),
@JsonValue(r'image/avif')
imageSlashAvif(r'image/avif');

const PhotoUploadRequestContentTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


