// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_metrics_guardrail.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminMetricsGuardrailCWProxy {
  AdminMetricsGuardrail invited(Ratio invited);

  AdminMetricsGuardrail organic(Ratio organic);

  AdminMetricsGuardrail ratio(num? ratio);

  AdminMetricsGuardrail triggered(bool triggered);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMetricsGuardrail(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMetricsGuardrail(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminMetricsGuardrail call({
    Ratio invited,
    Ratio organic,
    num? ratio,
    bool triggered,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminMetricsGuardrail.copyWith(...)` or call `instanceOfAdminMetricsGuardrail.copyWith.fieldName(value)` for a single field.
class _$AdminMetricsGuardrailCWProxyImpl
    implements _$AdminMetricsGuardrailCWProxy {
  const _$AdminMetricsGuardrailCWProxyImpl(this._value);

  final AdminMetricsGuardrail _value;

  @override
  AdminMetricsGuardrail invited(Ratio invited) => call(invited: invited);

  @override
  AdminMetricsGuardrail organic(Ratio organic) => call(organic: organic);

  @override
  AdminMetricsGuardrail ratio(num? ratio) => call(ratio: ratio);

  @override
  AdminMetricsGuardrail triggered(bool triggered) => call(triggered: triggered);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMetricsGuardrail(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMetricsGuardrail(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminMetricsGuardrail call({
    Object? invited = const $CopyWithPlaceholder(),
    Object? organic = const $CopyWithPlaceholder(),
    Object? ratio = const $CopyWithPlaceholder(),
    Object? triggered = const $CopyWithPlaceholder(),
  }) {
    return AdminMetricsGuardrail(
      invited: invited == const $CopyWithPlaceholder() || invited == null
          ? _value.invited
          // ignore: cast_nullable_to_non_nullable
          : invited as Ratio,
      organic: organic == const $CopyWithPlaceholder() || organic == null
          ? _value.organic
          // ignore: cast_nullable_to_non_nullable
          : organic as Ratio,
      ratio: ratio == const $CopyWithPlaceholder()
          ? _value.ratio
          // ignore: cast_nullable_to_non_nullable
          : ratio as num?,
      triggered: triggered == const $CopyWithPlaceholder() || triggered == null
          ? _value.triggered
          // ignore: cast_nullable_to_non_nullable
          : triggered as bool,
    );
  }
}

extension $AdminMetricsGuardrailCopyWith on AdminMetricsGuardrail {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminMetricsGuardrail.copyWith(...)` or `instanceOfAdminMetricsGuardrail.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminMetricsGuardrailCWProxy get copyWith =>
      _$AdminMetricsGuardrailCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminMetricsGuardrail _$AdminMetricsGuardrailFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminMetricsGuardrail', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['invited', 'organic', 'ratio', 'triggered'],
  );
  final val = AdminMetricsGuardrail(
    invited: $checkedConvert(
      'invited',
      (v) => Ratio.fromJson(v as Map<String, dynamic>),
    ),
    organic: $checkedConvert(
      'organic',
      (v) => Ratio.fromJson(v as Map<String, dynamic>),
    ),
    ratio: $checkedConvert('ratio', (v) => v as num?),
    triggered: $checkedConvert('triggered', (v) => v as bool),
  );
  return val;
});

Map<String, dynamic> _$AdminMetricsGuardrailToJson(
  AdminMetricsGuardrail instance,
) => <String, dynamic>{
  'invited': instance.invited.toJson(),
  'organic': instance.organic.toJson(),
  'ratio': instance.ratio,
  'triggered': instance.triggered,
};
