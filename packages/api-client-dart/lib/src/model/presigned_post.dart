//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'presigned_post.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PresignedPost {
  /// Returns a new [PresignedPost] instance.
  PresignedPost({

    required  this.url,

    required  this.fields,
  });

  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'fields',
    required: true,
    includeIfNull: false,
  )


  final Map<String, String> fields;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PresignedPost &&
      other.url == url &&
      other.fields == fields;

    @override
    int get hashCode =>
        url.hashCode +
        fields.hashCode;

  factory PresignedPost.fromJson(Map<String, dynamic> json) => _$PresignedPostFromJson(json);

  Map<String, dynamic> toJson() => _$PresignedPostToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

