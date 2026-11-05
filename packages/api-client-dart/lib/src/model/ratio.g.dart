// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ratio.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RatioCWProxy {
  Ratio numerator(int numerator);

  Ratio denominator(int denominator);

  Ratio value(num? value);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Ratio(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Ratio(...).copyWith(id: 12, name: "My name")
  /// ```
  Ratio call({int numerator, int denominator, num? value});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRatio.copyWith(...)` or call `instanceOfRatio.copyWith.fieldName(value)` for a single field.
class _$RatioCWProxyImpl implements _$RatioCWProxy {
  const _$RatioCWProxyImpl(this._value);

  final Ratio _value;

  @override
  Ratio numerator(int numerator) => call(numerator: numerator);

  @override
  Ratio denominator(int denominator) => call(denominator: denominator);

  @override
  Ratio value(num? value) => call(value: value);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Ratio(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Ratio(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Ratio call({
    Object? numerator = const $CopyWithPlaceholder(),
    Object? denominator = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
  }) {
    return Ratio(
      numerator: numerator == const $CopyWithPlaceholder() || numerator == null
          ? _value.numerator
          // ignore: cast_nullable_to_non_nullable
          : numerator as int,
      denominator:
          denominator == const $CopyWithPlaceholder() || denominator == null
          ? _value.denominator
          // ignore: cast_nullable_to_non_nullable
          : denominator as int,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as num?,
    );
  }
}

extension $RatioCopyWith on Ratio {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRatio.copyWith(...)` or `instanceOfRatio.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RatioCWProxy get copyWith => _$RatioCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ratio _$RatioFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Ratio',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['numerator', 'denominator', 'value']);
    final val = Ratio(
      numerator: $checkedConvert('numerator', (v) => (v as num).toInt()),
      denominator: $checkedConvert('denominator', (v) => (v as num).toInt()),
      value: $checkedConvert('value', (v) => v as num?),
    );
    return val;
  },
);

Map<String, dynamic> _$RatioToJson(Ratio instance) => <String, dynamic>{
  'numerator': instance.numerator,
  'denominator': instance.denominator,
  'value': instance.value,
};
