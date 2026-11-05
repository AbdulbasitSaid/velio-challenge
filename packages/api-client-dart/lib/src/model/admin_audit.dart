//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/admin_audit_failures_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_audit.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminAudit {
  /// Returns a new [AdminAudit] instance.
  AdminAudit({

    required  this.ranAt,

    required  this.failures,
  });

  @JsonKey(
    
    name: r'ranAt',
    required: true,
    includeIfNull: false,
  )


  final DateTime ranAt;



  @JsonKey(
    
    name: r'failures',
    required: true,
    includeIfNull: false,
  )


  final List<AdminAuditFailuresInner> failures;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminAudit &&
      other.ranAt == ranAt &&
      other.failures == failures;

    @override
    int get hashCode =>
        ranAt.hashCode +
        failures.hashCode;

  factory AdminAudit.fromJson(Map<String, dynamic> json) => _$AdminAuditFromJson(json);

  Map<String, dynamic> toJson() => _$AdminAuditToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

