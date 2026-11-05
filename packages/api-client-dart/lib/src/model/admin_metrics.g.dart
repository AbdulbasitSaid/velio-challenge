// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_metrics.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminMetricsCWProxy {
  AdminMetrics generatedAt(DateTime generatedAt);

  AdminMetrics days(int days);

  AdminMetrics goals(List<AdminGoal> goals);

  AdminMetrics funnel(List<AdminMetricsFunnelInner> funnel);

  AdminMetrics blendedOpenToClaim(Ratio blendedOpenToClaim);

  AdminMetrics inviteRate(List<AdminMetricsInviteRateInner> inviteRate);

  AdminMetrics kFactor(List<AdminMetricsKFactorInner> kFactor);

  AdminMetrics plansHappened(Ratio plansHappened);

  AdminMetrics guardrail(AdminMetricsGuardrail guardrail);

  AdminMetrics holdout(List<AdminMetricsHoldoutInner> holdout);

  AdminMetrics audit(AdminMetricsAudit audit);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMetrics(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMetrics(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminMetrics call({
    DateTime generatedAt,
    int days,
    List<AdminGoal> goals,
    List<AdminMetricsFunnelInner> funnel,
    Ratio blendedOpenToClaim,
    List<AdminMetricsInviteRateInner> inviteRate,
    List<AdminMetricsKFactorInner> kFactor,
    Ratio plansHappened,
    AdminMetricsGuardrail guardrail,
    List<AdminMetricsHoldoutInner> holdout,
    AdminMetricsAudit audit,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminMetrics.copyWith(...)` or call `instanceOfAdminMetrics.copyWith.fieldName(value)` for a single field.
class _$AdminMetricsCWProxyImpl implements _$AdminMetricsCWProxy {
  const _$AdminMetricsCWProxyImpl(this._value);

  final AdminMetrics _value;

  @override
  AdminMetrics generatedAt(DateTime generatedAt) =>
      call(generatedAt: generatedAt);

  @override
  AdminMetrics days(int days) => call(days: days);

  @override
  AdminMetrics goals(List<AdminGoal> goals) => call(goals: goals);

  @override
  AdminMetrics funnel(List<AdminMetricsFunnelInner> funnel) =>
      call(funnel: funnel);

  @override
  AdminMetrics blendedOpenToClaim(Ratio blendedOpenToClaim) =>
      call(blendedOpenToClaim: blendedOpenToClaim);

  @override
  AdminMetrics inviteRate(List<AdminMetricsInviteRateInner> inviteRate) =>
      call(inviteRate: inviteRate);

  @override
  AdminMetrics kFactor(List<AdminMetricsKFactorInner> kFactor) =>
      call(kFactor: kFactor);

  @override
  AdminMetrics plansHappened(Ratio plansHappened) =>
      call(plansHappened: plansHappened);

  @override
  AdminMetrics guardrail(AdminMetricsGuardrail guardrail) =>
      call(guardrail: guardrail);

  @override
  AdminMetrics holdout(List<AdminMetricsHoldoutInner> holdout) =>
      call(holdout: holdout);

  @override
  AdminMetrics audit(AdminMetricsAudit audit) => call(audit: audit);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMetrics(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMetrics(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminMetrics call({
    Object? generatedAt = const $CopyWithPlaceholder(),
    Object? days = const $CopyWithPlaceholder(),
    Object? goals = const $CopyWithPlaceholder(),
    Object? funnel = const $CopyWithPlaceholder(),
    Object? blendedOpenToClaim = const $CopyWithPlaceholder(),
    Object? inviteRate = const $CopyWithPlaceholder(),
    Object? kFactor = const $CopyWithPlaceholder(),
    Object? plansHappened = const $CopyWithPlaceholder(),
    Object? guardrail = const $CopyWithPlaceholder(),
    Object? holdout = const $CopyWithPlaceholder(),
    Object? audit = const $CopyWithPlaceholder(),
  }) {
    return AdminMetrics(
      generatedAt:
          generatedAt == const $CopyWithPlaceholder() || generatedAt == null
          ? _value.generatedAt
          // ignore: cast_nullable_to_non_nullable
          : generatedAt as DateTime,
      days: days == const $CopyWithPlaceholder() || days == null
          ? _value.days
          // ignore: cast_nullable_to_non_nullable
          : days as int,
      goals: goals == const $CopyWithPlaceholder() || goals == null
          ? _value.goals
          // ignore: cast_nullable_to_non_nullable
          : goals as List<AdminGoal>,
      funnel: funnel == const $CopyWithPlaceholder() || funnel == null
          ? _value.funnel
          // ignore: cast_nullable_to_non_nullable
          : funnel as List<AdminMetricsFunnelInner>,
      blendedOpenToClaim:
          blendedOpenToClaim == const $CopyWithPlaceholder() ||
              blendedOpenToClaim == null
          ? _value.blendedOpenToClaim
          // ignore: cast_nullable_to_non_nullable
          : blendedOpenToClaim as Ratio,
      inviteRate:
          inviteRate == const $CopyWithPlaceholder() || inviteRate == null
          ? _value.inviteRate
          // ignore: cast_nullable_to_non_nullable
          : inviteRate as List<AdminMetricsInviteRateInner>,
      kFactor: kFactor == const $CopyWithPlaceholder() || kFactor == null
          ? _value.kFactor
          // ignore: cast_nullable_to_non_nullable
          : kFactor as List<AdminMetricsKFactorInner>,
      plansHappened:
          plansHappened == const $CopyWithPlaceholder() || plansHappened == null
          ? _value.plansHappened
          // ignore: cast_nullable_to_non_nullable
          : plansHappened as Ratio,
      guardrail: guardrail == const $CopyWithPlaceholder() || guardrail == null
          ? _value.guardrail
          // ignore: cast_nullable_to_non_nullable
          : guardrail as AdminMetricsGuardrail,
      holdout: holdout == const $CopyWithPlaceholder() || holdout == null
          ? _value.holdout
          // ignore: cast_nullable_to_non_nullable
          : holdout as List<AdminMetricsHoldoutInner>,
      audit: audit == const $CopyWithPlaceholder() || audit == null
          ? _value.audit
          // ignore: cast_nullable_to_non_nullable
          : audit as AdminMetricsAudit,
    );
  }
}

extension $AdminMetricsCopyWith on AdminMetrics {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminMetrics.copyWith(...)` or `instanceOfAdminMetrics.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminMetricsCWProxy get copyWith => _$AdminMetricsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminMetrics _$AdminMetricsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminMetrics', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'generatedAt',
      'days',
      'goals',
      'funnel',
      'blendedOpenToClaim',
      'inviteRate',
      'kFactor',
      'plansHappened',
      'guardrail',
      'holdout',
      'audit',
    ],
  );
  final val = AdminMetrics(
    generatedAt: $checkedConvert(
      'generatedAt',
      (v) => DateTime.parse(v as String),
    ),
    days: $checkedConvert('days', (v) => (v as num).toInt()),
    goals: $checkedConvert(
      'goals',
      (v) => (v as List<dynamic>)
          .map((e) => AdminGoal.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    funnel: $checkedConvert(
      'funnel',
      (v) => (v as List<dynamic>)
          .map(
            (e) => AdminMetricsFunnelInner.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    blendedOpenToClaim: $checkedConvert(
      'blendedOpenToClaim',
      (v) => Ratio.fromJson(v as Map<String, dynamic>),
    ),
    inviteRate: $checkedConvert(
      'inviteRate',
      (v) => (v as List<dynamic>)
          .map(
            (e) =>
                AdminMetricsInviteRateInner.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    kFactor: $checkedConvert(
      'kFactor',
      (v) => (v as List<dynamic>)
          .map(
            (e) => AdminMetricsKFactorInner.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    plansHappened: $checkedConvert(
      'plansHappened',
      (v) => Ratio.fromJson(v as Map<String, dynamic>),
    ),
    guardrail: $checkedConvert(
      'guardrail',
      (v) => AdminMetricsGuardrail.fromJson(v as Map<String, dynamic>),
    ),
    holdout: $checkedConvert(
      'holdout',
      (v) => (v as List<dynamic>)
          .map(
            (e) => AdminMetricsHoldoutInner.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    audit: $checkedConvert(
      'audit',
      (v) => AdminMetricsAudit.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$AdminMetricsToJson(AdminMetrics instance) =>
    <String, dynamic>{
      'generatedAt': instance.generatedAt.toIso8601String(),
      'days': instance.days,
      'goals': instance.goals.map((e) => e.toJson()).toList(),
      'funnel': instance.funnel.map((e) => e.toJson()).toList(),
      'blendedOpenToClaim': instance.blendedOpenToClaim.toJson(),
      'inviteRate': instance.inviteRate.map((e) => e.toJson()).toList(),
      'kFactor': instance.kFactor.map((e) => e.toJson()).toList(),
      'plansHappened': instance.plansHappened.toJson(),
      'guardrail': instance.guardrail.toJson(),
      'holdout': instance.holdout.map((e) => e.toJson()).toList(),
      'audit': instance.audit.toJson(),
    };
