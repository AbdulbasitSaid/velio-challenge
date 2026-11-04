//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/plan_view_viewer_booking.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan_view_viewer.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanViewViewer {
  /// Returns a new [PlanViewViewer] instance.
  PlanViewViewer({

    required  this.booking,

    required  this.canInvite,
  });

  @JsonKey(
    
    name: r'booking',
    required: true,
    includeIfNull: false,
  )


  final PlanViewViewerBooking booking;



  @JsonKey(
    
    name: r'canInvite',
    required: true,
    includeIfNull: false,
  )


  final bool canInvite;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlanViewViewer &&
      other.booking == booking &&
      other.canInvite == canInvite;

    @override
    int get hashCode =>
        booking.hashCode +
        canInvite.hashCode;

  factory PlanViewViewer.fromJson(Map<String, dynamic> json) => _$PlanViewViewerFromJson(json);

  Map<String, dynamic> toJson() => _$PlanViewViewerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

