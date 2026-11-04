//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/public_activity_viewer_booking.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_activity_viewer.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicActivityViewer {
  /// Returns a new [PublicActivityViewer] instance.
  PublicActivityViewer({

    required  this.isHost,

    required  this.booking,
  });

  @JsonKey(
    
    name: r'isHost',
    required: true,
    includeIfNull: false,
  )


  final bool isHost;



  @JsonKey(
    
    name: r'booking',
    required: true,
    includeIfNull: true,
  )


  final PublicActivityViewerBooking? booking;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PublicActivityViewer &&
      other.isHost == isHost &&
      other.booking == booking;

    @override
    int get hashCode =>
        isHost.hashCode +
        (booking == null ? 0 : booking.hashCode);

  factory PublicActivityViewer.fromJson(Map<String, dynamic> json) => _$PublicActivityViewerFromJson(json);

  Map<String, dynamic> toJson() => _$PublicActivityViewerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

