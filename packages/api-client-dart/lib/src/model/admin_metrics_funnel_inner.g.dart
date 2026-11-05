// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_metrics_funnel_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminMetricsFunnelInnerCWProxy {
  AdminMetricsFunnelInner rail(AdminMetricsFunnelInnerRailEnum rail);

  AdminMetricsFunnelInner invites(int invites);

  AdminMetricsFunnelInner opens(int opens);

  AdminMetricsFunnelInner claims(int claims);

  AdminMetricsFunnelInner openToClaim(Ratio openToClaim);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMetricsFunnelInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMetricsFunnelInner(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminMetricsFunnelInner call({
    AdminMetricsFunnelInnerRailEnum rail,
    int invites,
    int opens,
    int claims,
    Ratio openToClaim,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminMetricsFunnelInner.copyWith(...)` or call `instanceOfAdminMetricsFunnelInner.copyWith.fieldName(value)` for a single field.
class _$AdminMetricsFunnelInnerCWProxyImpl
    implements _$AdminMetricsFunnelInnerCWProxy {
  const _$AdminMetricsFunnelInnerCWProxyImpl(this._value);

  final AdminMetricsFunnelInner _value;

  @override
  AdminMetricsFunnelInner rail(AdminMetricsFunnelInnerRailEnum rail) =>
      call(rail: rail);

  @override
  AdminMetricsFunnelInner invites(int invites) => call(invites: invites);

  @override
  AdminMetricsFunnelInner opens(int opens) => call(opens: opens);

  @override
  AdminMetricsFunnelInner claims(int claims) => call(claims: claims);

  @override
  AdminMetricsFunnelInner openToClaim(Ratio openToClaim) =>
      call(openToClaim: openToClaim);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMetricsFunnelInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMetricsFunnelInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminMetricsFunnelInner call({
    Object? rail = const $CopyWithPlaceholder(),
    Object? invites = const $CopyWithPlaceholder(),
    Object? opens = const $CopyWithPlaceholder(),
    Object? claims = const $CopyWithPlaceholder(),
    Object? openToClaim = const $CopyWithPlaceholder(),
  }) {
    return AdminMetricsFunnelInner(
      rail: rail == const $CopyWithPlaceholder() || rail == null
          ? _value.rail
          // ignore: cast_nullable_to_non_nullable
          : rail as AdminMetricsFunnelInnerRailEnum,
      invites: invites == const $CopyWithPlaceholder() || invites == null
          ? _value.invites
          // ignore: cast_nullable_to_non_nullable
          : invites as int,
      opens: opens == const $CopyWithPlaceholder() || opens == null
          ? _value.opens
          // ignore: cast_nullable_to_non_nullable
          : opens as int,
      claims: claims == const $CopyWithPlaceholder() || claims == null
          ? _value.claims
          // ignore: cast_nullable_to_non_nullable
          : claims as int,
      openToClaim:
          openToClaim == const $CopyWithPlaceholder() || openToClaim == null
          ? _value.openToClaim
          // ignore: cast_nullable_to_non_nullable
          : openToClaim as Ratio,
    );
  }
}

extension $AdminMetricsFunnelInnerCopyWith on AdminMetricsFunnelInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminMetricsFunnelInner.copyWith(...)` or `instanceOfAdminMetricsFunnelInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminMetricsFunnelInnerCWProxy get copyWith =>
      _$AdminMetricsFunnelInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminMetricsFunnelInner _$AdminMetricsFunnelInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminMetricsFunnelInner', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['rail', 'invites', 'opens', 'claims', 'openToClaim'],
  );
  final val = AdminMetricsFunnelInner(
    rail: $checkedConvert(
      'rail',
      (v) => $enumDecode(_$AdminMetricsFunnelInnerRailEnumEnumMap, v),
    ),
    invites: $checkedConvert('invites', (v) => (v as num).toInt()),
    opens: $checkedConvert('opens', (v) => (v as num).toInt()),
    claims: $checkedConvert('claims', (v) => (v as num).toInt()),
    openToClaim: $checkedConvert(
      'openToClaim',
      (v) => Ratio.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$AdminMetricsFunnelInnerToJson(
  AdminMetricsFunnelInner instance,
) => <String, dynamic>{
  'rail': _$AdminMetricsFunnelInnerRailEnumEnumMap[instance.rail]!,
  'invites': instance.invites,
  'opens': instance.opens,
  'claims': instance.claims,
  'openToClaim': instance.openToClaim.toJson(),
};

const _$AdminMetricsFunnelInnerRailEnumEnumMap = {
  AdminMetricsFunnelInnerRailEnum.vouch: 'vouch',
  AdminMetricsFunnelInnerRailEnum.public: 'public',
};
