//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_goal.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminGoal {
  /// Returns a new [AdminGoal] instance.
  AdminGoal({

    required  this.id,

    required  this.label,

    required  this.unit,

    required  this.value,

    required  this.target,

    required  this.trigger,

    required  this.triggered,

    required  this.sample,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final AdminGoalIdEnum id;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;



  @JsonKey(
    
    name: r'unit',
    required: true,
    includeIfNull: false,
  )


  final AdminGoalUnitEnum unit;



  @JsonKey(
    
    name: r'value',
    required: true,
    includeIfNull: true,
  )


  final num? value;



  @JsonKey(
    
    name: r'target',
    required: true,
    includeIfNull: true,
  )


  final num? target;



  @JsonKey(
    
    name: r'trigger',
    required: true,
    includeIfNull: false,
  )


  final String trigger;



  @JsonKey(
    
    name: r'triggered',
    required: true,
    includeIfNull: false,
  )


  final bool triggered;



  @JsonKey(
    
    name: r'sample',
    required: true,
    includeIfNull: false,
  )


  final int sample;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminGoal &&
      other.id == id &&
      other.label == label &&
      other.unit == unit &&
      other.value == value &&
      other.target == target &&
      other.trigger == trigger &&
      other.triggered == triggered &&
      other.sample == sample;

    @override
    int get hashCode =>
        id.hashCode +
        label.hashCode +
        unit.hashCode +
        (value == null ? 0 : value.hashCode) +
        (target == null ? 0 : target.hashCode) +
        trigger.hashCode +
        triggered.hashCode +
        sample.hashCode;

  factory AdminGoal.fromJson(Map<String, dynamic> json) => _$AdminGoalFromJson(json);

  Map<String, dynamic> toJson() => _$AdminGoalToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum AdminGoalIdEnum {
@JsonValue(r'no_oversell')
noOversell(r'no_oversell'),
@JsonValue(r'booking_success')
bookingSuccess(r'booking_success'),
@JsonValue(r'availability_live')
availabilityLive(r'availability_live'),
@JsonValue(r'bookers_invite')
bookersInvite(r'bookers_invite'),
@JsonValue(r'invites_convert_vouch')
invitesConvertVouch(r'invites_convert_vouch'),
@JsonValue(r'invites_convert_public')
invitesConvertPublic(r'invites_convert_public');

const AdminGoalIdEnum(this.value);

final String value;

@override
String toString() => value;
}


enum AdminGoalUnitEnum {
@JsonValue(r'count')
count(r'count'),
@JsonValue(r'ratio')
ratio(r'ratio'),
@JsonValue(r'seconds')
seconds(r'seconds');

const AdminGoalUnitEnum(this.value);

final String value;

@override
String toString() => value;
}


