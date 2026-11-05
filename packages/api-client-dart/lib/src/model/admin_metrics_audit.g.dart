// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_metrics_audit.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminMetricsAuditCWProxy {
  AdminMetricsAudit ranAt(DateTime? ranAt);

  AdminMetricsAudit failures(int? failures);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMetricsAudit(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMetricsAudit(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminMetricsAudit call({DateTime? ranAt, int? failures});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminMetricsAudit.copyWith(...)` or call `instanceOfAdminMetricsAudit.copyWith.fieldName(value)` for a single field.
class _$AdminMetricsAuditCWProxyImpl implements _$AdminMetricsAuditCWProxy {
  const _$AdminMetricsAuditCWProxyImpl(this._value);

  final AdminMetricsAudit _value;

  @override
  AdminMetricsAudit ranAt(DateTime? ranAt) => call(ranAt: ranAt);

  @override
  AdminMetricsAudit failures(int? failures) => call(failures: failures);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMetricsAudit(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMetricsAudit(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminMetricsAudit call({
    Object? ranAt = const $CopyWithPlaceholder(),
    Object? failures = const $CopyWithPlaceholder(),
  }) {
    return AdminMetricsAudit(
      ranAt: ranAt == const $CopyWithPlaceholder()
          ? _value.ranAt
          // ignore: cast_nullable_to_non_nullable
          : ranAt as DateTime?,
      failures: failures == const $CopyWithPlaceholder()
          ? _value.failures
          // ignore: cast_nullable_to_non_nullable
          : failures as int?,
    );
  }
}

extension $AdminMetricsAuditCopyWith on AdminMetricsAudit {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminMetricsAudit.copyWith(...)` or `instanceOfAdminMetricsAudit.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminMetricsAuditCWProxy get copyWith =>
      _$AdminMetricsAuditCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminMetricsAudit _$AdminMetricsAuditFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminMetricsAudit', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['ranAt', 'failures']);
      final val = AdminMetricsAudit(
        ranAt: $checkedConvert(
          'ranAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        failures: $checkedConvert('failures', (v) => (v as num?)?.toInt()),
      );
      return val;
    });

Map<String, dynamic> _$AdminMetricsAuditToJson(AdminMetricsAudit instance) =>
    <String, dynamic>{
      'ranAt': instance.ranAt?.toIso8601String(),
      'failures': instance.failures,
    };
