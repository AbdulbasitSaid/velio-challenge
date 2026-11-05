//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/ratio.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_metrics_guardrail.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMetricsGuardrail {
  /// Returns a new [AdminMetricsGuardrail] instance.
  AdminMetricsGuardrail({

    required  this.invited,

    required  this.organic,

    required  this.ratio,

    required  this.triggered,
  });

  @JsonKey(
    
    name: r'invited',
    required: true,
    includeIfNull: false,
  )


  final Ratio invited;



  @JsonKey(
    
    name: r'organic',
    required: true,
    includeIfNull: false,
  )


  final Ratio organic;



  @JsonKey(
    
    name: r'ratio',
    required: true,
    includeIfNull: true,
  )


  final num? ratio;



  @JsonKey(
    
    name: r'triggered',
    required: true,
    includeIfNull: false,
  )


  final bool triggered;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminMetricsGuardrail &&
      other.invited == invited &&
      other.organic == organic &&
      other.ratio == ratio &&
      other.triggered == triggered;

    @override
    int get hashCode =>
        invited.hashCode +
        organic.hashCode +
        (ratio == null ? 0 : ratio.hashCode) +
        triggered.hashCode;

  factory AdminMetricsGuardrail.fromJson(Map<String, dynamic> json) => _$AdminMetricsGuardrailFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMetricsGuardrailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

