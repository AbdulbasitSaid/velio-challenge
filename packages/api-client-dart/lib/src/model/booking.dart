//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'booking.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Booking {
  /// Returns a new [Booking] instance.
  Booking({

    required  this.id,

    required  this.ref,

    required  this.activityId,

    required  this.planId,

    required  this.source_,

    required  this.status,

    required  this.createdAt,
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
    
    name: r'activityId',
    required: true,
    includeIfNull: false,
  )


  final String activityId;



  @JsonKey(
    
    name: r'planId',
    required: true,
    includeIfNull: false,
  )


  final String planId;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final BookingSource_Enum source_;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final BookingStatusEnum status;



  @JsonKey(
    
    name: r'createdAt',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Booking &&
      other.id == id &&
      other.ref == ref &&
      other.activityId == activityId &&
      other.planId == planId &&
      other.source_ == source_ &&
      other.status == status &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        ref.hashCode +
        activityId.hashCode +
        planId.hashCode +
        source_.hashCode +
        status.hashCode +
        createdAt.hashCode;

  factory Booking.fromJson(Map<String, dynamic> json) => _$BookingFromJson(json);

  Map<String, dynamic> toJson() => _$BookingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum BookingSource_Enum {
@JsonValue(r'direct')
direct(r'direct'),
@JsonValue(r'vouch')
vouch(r'vouch'),
@JsonValue(r'public')
public(r'public');

const BookingSource_Enum(this.value);

final String value;

@override
String toString() => value;
}


enum BookingStatusEnum {
@JsonValue(r'confirmed')
confirmed(r'confirmed'),
@JsonValue(r'removed')
removed(r'removed');

const BookingStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


