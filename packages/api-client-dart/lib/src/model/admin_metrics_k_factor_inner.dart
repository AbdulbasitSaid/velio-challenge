//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_metrics_k_factor_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMetricsKFactorInner {
  /// Returns a new [AdminMetricsKFactorInner] instance.
  AdminMetricsKFactorInner({

    required  this.rail,

    required  this.newUsers,

    required  this.inviters,

    required  this.value,
  });

  @JsonKey(
    
    name: r'rail',
    required: true,
    includeIfNull: false,
  )


  final AdminMetricsKFactorInnerRailEnum rail;



  @JsonKey(
    
    name: r'newUsers',
    required: true,
    includeIfNull: false,
  )


  final int newUsers;



  @JsonKey(
    
    name: r'inviters',
    required: true,
    includeIfNull: false,
  )


  final int inviters;



  @JsonKey(
    
    name: r'value',
    required: true,
    includeIfNull: true,
  )


  final num? value;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminMetricsKFactorInner &&
      other.rail == rail &&
      other.newUsers == newUsers &&
      other.inviters == inviters &&
      other.value == value;

    @override
    int get hashCode =>
        rail.hashCode +
        newUsers.hashCode +
        inviters.hashCode +
        (value == null ? 0 : value.hashCode);

  factory AdminMetricsKFactorInner.fromJson(Map<String, dynamic> json) => _$AdminMetricsKFactorInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMetricsKFactorInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

enum AdminMetricsKFactorInnerRailEnum {
@JsonValue(r'vouch')
vouch(r'vouch'),
@JsonValue(r'public')
public(r'public');

const AdminMetricsKFactorInnerRailEnum(this.value);

final String value;

@override
String toString() => value;
}


