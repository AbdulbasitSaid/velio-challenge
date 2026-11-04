//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/booking.dart';
import 'package:velio_api/src/model/activity_state.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'booking_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BookingResponse {
  /// Returns a new [BookingResponse] instance.
  BookingResponse({

    required  this.booking,

    required  this.activity,
  });

  @JsonKey(
    
    name: r'booking',
    required: true,
    includeIfNull: false,
  )


  final Booking booking;



  @JsonKey(
    
    name: r'activity',
    required: true,
    includeIfNull: false,
  )


  final ActivityState activity;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BookingResponse &&
      other.booking == booking &&
      other.activity == activity;

    @override
    int get hashCode =>
        booking.hashCode +
        activity.hashCode;

  factory BookingResponse.fromJson(Map<String, dynamic> json) => _$BookingResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BookingResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

