//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_activity_viewer_booking.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicActivityViewerBooking {
  /// Returns a new [PublicActivityViewerBooking] instance.
  PublicActivityViewerBooking({

    required  this.id,

    required  this.planId,

    required  this.status,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'planId',
    required: true,
    includeIfNull: false,
  )


  final String planId;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final PublicActivityViewerBookingStatusEnum status;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PublicActivityViewerBooking &&
      other.id == id &&
      other.planId == planId &&
      other.status == status;

    @override
    int get hashCode =>
        id.hashCode +
        planId.hashCode +
        status.hashCode;

  factory PublicActivityViewerBooking.fromJson(Map<String, dynamic> json) => _$PublicActivityViewerBookingFromJson(json);

  Map<String, dynamic> toJson() => _$PublicActivityViewerBookingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum PublicActivityViewerBookingStatusEnum {
@JsonValue(r'confirmed')
confirmed(r'confirmed'),
@JsonValue(r'removed')
removed(r'removed');

const PublicActivityViewerBookingStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


