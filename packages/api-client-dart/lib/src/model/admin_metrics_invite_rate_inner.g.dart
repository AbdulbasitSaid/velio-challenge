// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_metrics_invite_rate_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminMetricsInviteRateInnerCWProxy {
  AdminMetricsInviteRateInner rail(AdminMetricsInviteRateInnerRailEnum rail);

  AdminMetricsInviteRateInner rate(Ratio rate);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMetricsInviteRateInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMetricsInviteRateInner(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminMetricsInviteRateInner call({
    AdminMetricsInviteRateInnerRailEnum rail,
    Ratio rate,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminMetricsInviteRateInner.copyWith(...)` or call `instanceOfAdminMetricsInviteRateInner.copyWith.fieldName(value)` for a single field.
class _$AdminMetricsInviteRateInnerCWProxyImpl
    implements _$AdminMetricsInviteRateInnerCWProxy {
  const _$AdminMetricsInviteRateInnerCWProxyImpl(this._value);

  final AdminMetricsInviteRateInner _value;

  @override
  AdminMetricsInviteRateInner rail(AdminMetricsInviteRateInnerRailEnum rail) =>
      call(rail: rail);

  @override
  AdminMetricsInviteRateInner rate(Ratio rate) => call(rate: rate);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMetricsInviteRateInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMetricsInviteRateInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminMetricsInviteRateInner call({
    Object? rail = const $CopyWithPlaceholder(),
    Object? rate = const $CopyWithPlaceholder(),
  }) {
    return AdminMetricsInviteRateInner(
      rail: rail == const $CopyWithPlaceholder() || rail == null
          ? _value.rail
          // ignore: cast_nullable_to_non_nullable
          : rail as AdminMetricsInviteRateInnerRailEnum,
      rate: rate == const $CopyWithPlaceholder() || rate == null
          ? _value.rate
          // ignore: cast_nullable_to_non_nullable
          : rate as Ratio,
    );
  }
}

extension $AdminMetricsInviteRateInnerCopyWith on AdminMetricsInviteRateInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminMetricsInviteRateInner.copyWith(...)` or `instanceOfAdminMetricsInviteRateInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminMetricsInviteRateInnerCWProxy get copyWith =>
      _$AdminMetricsInviteRateInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminMetricsInviteRateInner _$AdminMetricsInviteRateInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminMetricsInviteRateInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['rail', 'rate']);
  final val = AdminMetricsInviteRateInner(
    rail: $checkedConvert(
      'rail',
      (v) => $enumDecode(_$AdminMetricsInviteRateInnerRailEnumEnumMap, v),
    ),
    rate: $checkedConvert(
      'rate',
      (v) => Ratio.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$AdminMetricsInviteRateInnerToJson(
  AdminMetricsInviteRateInner instance,
) => <String, dynamic>{
  'rail': _$AdminMetricsInviteRateInnerRailEnumEnumMap[instance.rail]!,
  'rate': instance.rate.toJson(),
};

const _$AdminMetricsInviteRateInnerRailEnumEnumMap = {
  AdminMetricsInviteRateInnerRailEnum.any: 'any',
  AdminMetricsInviteRateInnerRailEnum.vouch: 'vouch',
  AdminMetricsInviteRateInnerRailEnum.public: 'public',
};
