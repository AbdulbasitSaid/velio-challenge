// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_metrics_k_factor_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminMetricsKFactorInnerCWProxy {
  AdminMetricsKFactorInner rail(AdminMetricsKFactorInnerRailEnum rail);

  AdminMetricsKFactorInner newUsers(int newUsers);

  AdminMetricsKFactorInner inviters(int inviters);

  AdminMetricsKFactorInner value(num? value);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMetricsKFactorInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMetricsKFactorInner(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminMetricsKFactorInner call({
    AdminMetricsKFactorInnerRailEnum rail,
    int newUsers,
    int inviters,
    num? value,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminMetricsKFactorInner.copyWith(...)` or call `instanceOfAdminMetricsKFactorInner.copyWith.fieldName(value)` for a single field.
class _$AdminMetricsKFactorInnerCWProxyImpl
    implements _$AdminMetricsKFactorInnerCWProxy {
  const _$AdminMetricsKFactorInnerCWProxyImpl(this._value);

  final AdminMetricsKFactorInner _value;

  @override
  AdminMetricsKFactorInner rail(AdminMetricsKFactorInnerRailEnum rail) =>
      call(rail: rail);

  @override
  AdminMetricsKFactorInner newUsers(int newUsers) => call(newUsers: newUsers);

  @override
  AdminMetricsKFactorInner inviters(int inviters) => call(inviters: inviters);

  @override
  AdminMetricsKFactorInner value(num? value) => call(value: value);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMetricsKFactorInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMetricsKFactorInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminMetricsKFactorInner call({
    Object? rail = const $CopyWithPlaceholder(),
    Object? newUsers = const $CopyWithPlaceholder(),
    Object? inviters = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return AdminMetricsKFactorInner(
      rail: rail == const $CopyWithPlaceholder() || rail == null
          ? _value.rail
          // ignore: cast_nullable_to_non_nullable
          : rail as AdminMetricsKFactorInnerRailEnum,
      newUsers: newUsers == const $CopyWithPlaceholder() || newUsers == null
          ? _value.newUsers
          // ignore: cast_nullable_to_non_nullable
          : newUsers as int,
      inviters: inviters == const $CopyWithPlaceholder() || inviters == null
          ? _value.inviters
          // ignore: cast_nullable_to_non_nullable
          : inviters as int,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as num?,
    );
  }
}

extension $AdminMetricsKFactorInnerCopyWith on AdminMetricsKFactorInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminMetricsKFactorInner.copyWith(...)` or `instanceOfAdminMetricsKFactorInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminMetricsKFactorInnerCWProxy get copyWith =>
      _$AdminMetricsKFactorInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminMetricsKFactorInner _$AdminMetricsKFactorInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminMetricsKFactorInner', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['rail', 'newUsers', 'inviters', 'value'],
  );
  final val = AdminMetricsKFactorInner(
    rail: $checkedConvert(
      'rail',
      (v) => $enumDecode(_$AdminMetricsKFactorInnerRailEnumEnumMap, v),
    ),
    newUsers: $checkedConvert('newUsers', (v) => (v as num).toInt()),
    inviters: $checkedConvert('inviters', (v) => (v as num).toInt()),
    value: $checkedConvert('value', (v) => v as num?),
  );
  return val;
});

Map<String, dynamic> _$AdminMetricsKFactorInnerToJson(
  AdminMetricsKFactorInner instance,
) => <String, dynamic>{
  'rail': _$AdminMetricsKFactorInnerRailEnumEnumMap[instance.rail]!,
  'newUsers': instance.newUsers,
  'inviters': instance.inviters,
  'value': instance.value,
};

const _$AdminMetricsKFactorInnerRailEnumEnumMap = {
  AdminMetricsKFactorInnerRailEnum.vouch: 'vouch',
  AdminMetricsKFactorInnerRailEnum.public: 'public',
};
