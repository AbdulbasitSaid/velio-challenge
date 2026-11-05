// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_audit.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminAuditCWProxy {
  AdminAudit ranAt(DateTime ranAt);

  AdminAudit failures(List<AdminAuditFailuresInner> failures);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminAudit(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminAudit(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminAudit call({DateTime ranAt, List<AdminAuditFailuresInner> failures});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminAudit.copyWith(...)` or call `instanceOfAdminAudit.copyWith.fieldName(value)` for a single field.
class _$AdminAuditCWProxyImpl implements _$AdminAuditCWProxy {
  const _$AdminAuditCWProxyImpl(this._value);

  final AdminAudit _value;

  @override
  AdminAudit ranAt(DateTime ranAt) => call(ranAt: ranAt);

  @override
  AdminAudit failures(List<AdminAuditFailuresInner> failures) =>
      call(failures: failures);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminAudit(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminAudit(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminAudit call({
    Object? ranAt = const $CopyWithPlaceholder(),
    Object? failures = const $CopyWithPlaceholder(),
  }) {
    return AdminAudit(
      ranAt: ranAt == const $CopyWithPlaceholder() || ranAt == null
          ? _value.ranAt
          // ignore: cast_nullable_to_non_nullable
          : ranAt as DateTime,
      failures: failures == const $CopyWithPlaceholder() || failures == null
          ? _value.failures
          // ignore: cast_nullable_to_non_nullable
          : failures as List<AdminAuditFailuresInner>,
    );
  }
}

extension $AdminAuditCopyWith on AdminAudit {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminAudit.copyWith(...)` or `instanceOfAdminAudit.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminAuditCWProxy get copyWith => _$AdminAuditCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminAudit _$AdminAuditFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminAudit', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['ranAt', 'failures']);
      final val = AdminAudit(
        ranAt: $checkedConvert('ranAt', (v) => DateTime.parse(v as String)),
        failures: $checkedConvert(
          'failures',
          (v) => (v as List<dynamic>)
              .map(
                (e) =>
                    AdminAuditFailuresInner.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminAuditToJson(AdminAudit instance) =>
    <String, dynamic>{
      'ranAt': instance.ranAt.toIso8601String(),
      'failures': instance.failures.map((e) => e.toJson()).toList(),
    };
