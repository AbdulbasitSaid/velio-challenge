// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_audit_failures_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminAuditFailuresInnerCWProxy {
  AdminAuditFailuresInner activityId(String activityId);

  AdminAuditFailuresInner table(String table);

  AdminAuditFailuresInner firstBadSeq(int firstBadSeq);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminAuditFailuresInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminAuditFailuresInner(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminAuditFailuresInner call({
    String activityId,
    String table,
    int firstBadSeq,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminAuditFailuresInner.copyWith(...)` or call `instanceOfAdminAuditFailuresInner.copyWith.fieldName(value)` for a single field.
class _$AdminAuditFailuresInnerCWProxyImpl
    implements _$AdminAuditFailuresInnerCWProxy {
  const _$AdminAuditFailuresInnerCWProxyImpl(this._value);

  final AdminAuditFailuresInner _value;

  @override
  AdminAuditFailuresInner activityId(String activityId) =>
      call(activityId: activityId);

  @override
  AdminAuditFailuresInner table(String table) => call(table: table);

  @override
  AdminAuditFailuresInner firstBadSeq(int firstBadSeq) =>
      call(firstBadSeq: firstBadSeq);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminAuditFailuresInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminAuditFailuresInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminAuditFailuresInner call({
    Object? activityId = const $CopyWithPlaceholder(),
    Object? table = const $CopyWithPlaceholder(),
    Object? firstBadSeq = const $CopyWithPlaceholder(),
  }) {
    return AdminAuditFailuresInner(
      activityId:
          activityId == const $CopyWithPlaceholder() || activityId == null
          ? _value.activityId
          // ignore: cast_nullable_to_non_nullable
          : activityId as String,
      table: table == const $CopyWithPlaceholder() || table == null
          ? _value.table
          // ignore: cast_nullable_to_non_nullable
          : table as String,
      firstBadSeq:
          firstBadSeq == const $CopyWithPlaceholder() || firstBadSeq == null
          ? _value.firstBadSeq
          // ignore: cast_nullable_to_non_nullable
          : firstBadSeq as int,
    );
  }
}

extension $AdminAuditFailuresInnerCopyWith on AdminAuditFailuresInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminAuditFailuresInner.copyWith(...)` or `instanceOfAdminAuditFailuresInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminAuditFailuresInnerCWProxy get copyWith =>
      _$AdminAuditFailuresInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminAuditFailuresInner _$AdminAuditFailuresInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminAuditFailuresInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['activityId', 'table', 'firstBadSeq']);
  final val = AdminAuditFailuresInner(
    activityId: $checkedConvert('activityId', (v) => v as String),
    table: $checkedConvert('table', (v) => v as String),
    firstBadSeq: $checkedConvert('firstBadSeq', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$AdminAuditFailuresInnerToJson(
  AdminAuditFailuresInner instance,
) => <String, dynamic>{
  'activityId': instance.activityId,
  'table': instance.table,
  'firstBadSeq': instance.firstBadSeq,
};
