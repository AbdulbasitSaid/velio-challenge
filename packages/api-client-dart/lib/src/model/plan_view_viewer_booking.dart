//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan_view_viewer_booking.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanViewViewerBooking {
  /// Returns a new [PlanViewViewerBooking] instance.
  PlanViewViewerBooking({

    required  this.id,

    required  this.ref,

    required  this.status,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'ref',
    required: true,
    includeIfNull: false,
  )


  final String ref;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final PlanViewViewerBookingStatusEnum status;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlanViewViewerBooking &&
      other.id == id &&
      other.ref == ref &&
      other.status == status;

    @override
    int get hashCode =>
        id.hashCode +
        ref.hashCode +
        status.hashCode;

  factory PlanViewViewerBooking.fromJson(Map<String, dynamic> json) => _$PlanViewViewerBookingFromJson(json);

  Map<String, dynamic> toJson() => _$PlanViewViewerBookingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum PlanViewViewerBookingStatusEnum {
@JsonValue(r'confirmed')
confirmed(r'confirmed'),
@JsonValue(r'removed')
removed(r'removed');

const PlanViewViewerBookingStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


