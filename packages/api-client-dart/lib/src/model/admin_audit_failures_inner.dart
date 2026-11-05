//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_audit_failures_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminAuditFailuresInner {
  /// Returns a new [AdminAuditFailuresInner] instance.
  AdminAuditFailuresInner({

    required  this.activityId,

    required  this.table,

    required  this.firstBadSeq,
  });

  @JsonKey(
    
    name: r'activityId',
    required: true,
    includeIfNull: false,
  )


  final String activityId;



  @JsonKey(
    
    name: r'table',
    required: true,
    includeIfNull: false,
  )


  final String table;



  @JsonKey(
    
    name: r'firstBadSeq',
    required: true,
    includeIfNull: false,
  )


  final int firstBadSeq;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminAuditFailuresInner &&
      other.activityId == activityId &&
      other.table == table &&
      other.firstBadSeq == firstBadSeq;

    @override
    int get hashCode =>
        activityId.hashCode +
        table.hashCode +
        firstBadSeq.hashCode;

  factory AdminAuditFailuresInner.fromJson(Map<String, dynamic> json) => _$AdminAuditFailuresInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AdminAuditFailuresInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

