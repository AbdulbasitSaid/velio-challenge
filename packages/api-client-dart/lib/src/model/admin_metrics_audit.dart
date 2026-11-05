//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_metrics_audit.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMetricsAudit {
  /// Returns a new [AdminMetricsAudit] instance.
  AdminMetricsAudit({

    required  this.ranAt,

    required  this.failures,
  });

  @JsonKey(
    
    name: r'ranAt',
    required: true,
    includeIfNull: true,
  )


  final DateTime? ranAt;



  @JsonKey(
    
    name: r'failures',
    required: true,
    includeIfNull: true,
  )


  final int? failures;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminMetricsAudit &&
      other.ranAt == ranAt &&
      other.failures == failures;

    @override
    int get hashCode =>
        (ranAt == null ? 0 : ranAt.hashCode) +
        (failures == null ? 0 : failures.hashCode);

  factory AdminMetricsAudit.fromJson(Map<String, dynamic> json) => _$AdminMetricsAuditFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMetricsAuditToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

