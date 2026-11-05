//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:velio_api/src/model/admin_metrics_holdout_inner.dart';
import 'package:velio_api/src/model/admin_metrics_guardrail.dart';
import 'package:velio_api/src/model/admin_metrics_audit.dart';
import 'package:velio_api/src/model/admin_metrics_funnel_inner.dart';
import 'package:velio_api/src/model/admin_goal.dart';
import 'package:velio_api/src/model/admin_metrics_invite_rate_inner.dart';
import 'package:velio_api/src/model/admin_metrics_k_factor_inner.dart';
import 'package:velio_api/src/model/ratio.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_metrics.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMetrics {
  /// Returns a new [AdminMetrics] instance.
  AdminMetrics({

    required  this.generatedAt,

    required  this.days,

    required  this.goals,

    required  this.funnel,

    required  this.blendedOpenToClaim,

    required  this.inviteRate,

    required  this.kFactor,

    required  this.plansHappened,

    required  this.guardrail,

    required  this.holdout,

    required  this.audit,
  });

  @JsonKey(
    
    name: r'generatedAt',
    required: true,
    includeIfNull: false,
  )


  final DateTime generatedAt;



  @JsonKey(
    
    name: r'days',
    required: true,
    includeIfNull: false,
  )


  final int days;



  @JsonKey(
    
    name: r'goals',
    required: true,
    includeIfNull: false,
  )


  final List<AdminGoal> goals;



  @JsonKey(
    
    name: r'funnel',
    required: true,
    includeIfNull: false,
  )


  final List<AdminMetricsFunnelInner> funnel;



  @JsonKey(
    
    name: r'blendedOpenToClaim',
    required: true,
    includeIfNull: false,
  )


  final Ratio blendedOpenToClaim;



  @JsonKey(
    
    name: r'inviteRate',
    required: true,
    includeIfNull: false,
  )


  final List<AdminMetricsInviteRateInner> inviteRate;



  @JsonKey(
    
    name: r'kFactor',
    required: true,
    includeIfNull: false,
  )


  final List<AdminMetricsKFactorInner> kFactor;



  @JsonKey(
    
    name: r'plansHappened',
    required: true,
    includeIfNull: false,
  )


  final Ratio plansHappened;



  @JsonKey(
    
    name: r'guardrail',
    required: true,
    includeIfNull: false,
  )


  final AdminMetricsGuardrail guardrail;



  @JsonKey(
    
    name: r'holdout',
    required: true,
    includeIfNull: false,
  )


  final List<AdminMetricsHoldoutInner> holdout;



  @JsonKey(
    
    name: r'audit',
    required: true,
    includeIfNull: false,
  )


  final AdminMetricsAudit audit;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminMetrics &&
      other.generatedAt == generatedAt &&
      other.days == days &&
      other.goals == goals &&
      other.funnel == funnel &&
      other.blendedOpenToClaim == blendedOpenToClaim &&
      other.inviteRate == inviteRate &&
      other.kFactor == kFactor &&
      other.plansHappened == plansHappened &&
      other.guardrail == guardrail &&
      other.holdout == holdout &&
      other.audit == audit;

    @override
    int get hashCode =>
        generatedAt.hashCode +
        days.hashCode +
        goals.hashCode +
        funnel.hashCode +
        blendedOpenToClaim.hashCode +
        inviteRate.hashCode +
        kFactor.hashCode +
        plansHappened.hashCode +
        guardrail.hashCode +
        holdout.hashCode +
        audit.hashCode;

  factory AdminMetrics.fromJson(Map<String, dynamic> json) => _$AdminMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMetricsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

