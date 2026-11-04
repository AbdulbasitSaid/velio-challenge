// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_create_one_of1.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteCreateOneOf1CWProxy {
  InviteCreateOneOf1 rail(InviteCreateOneOf1RailEnum rail);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteCreateOneOf1(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteCreateOneOf1(...).copyWith(id: 12, name: "My name")
  /// ```
  InviteCreateOneOf1 call({InviteCreateOneOf1RailEnum rail});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInviteCreateOneOf1.copyWith(...)` or call `instanceOfInviteCreateOneOf1.copyWith.fieldName(value)` for a single field.
class _$InviteCreateOneOf1CWProxyImpl implements _$InviteCreateOneOf1CWProxy {
  const _$InviteCreateOneOf1CWProxyImpl(this._value);

  final InviteCreateOneOf1 _value;

  @override
  InviteCreateOneOf1 rail(InviteCreateOneOf1RailEnum rail) => call(rail: rail);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InviteCreateOneOf1(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InviteCreateOneOf1(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InviteCreateOneOf1 call({Object? rail = const $CopyWithPlaceholder()}) {
    return InviteCreateOneOf1(
      rail: rail == const $CopyWithPlaceholder() || rail == null
          ? _value.rail
          // ignore: cast_nullable_to_non_nullable
          : rail as InviteCreateOneOf1RailEnum,
    );
  }
}

extension $InviteCreateOneOf1CopyWith on InviteCreateOneOf1 {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInviteCreateOneOf1.copyWith(...)` or `instanceOfInviteCreateOneOf1.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteCreateOneOf1CWProxy get copyWith =>
      _$InviteCreateOneOf1CWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteCreateOneOf1 _$InviteCreateOneOf1FromJson(Map<String, dynamic> json) =>
    $checkedCreate('InviteCreateOneOf1', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['rail']);
      final val = InviteCreateOneOf1(
        rail: $checkedConvert(
          'rail',
          (v) => $enumDecode(_$InviteCreateOneOf1RailEnumEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$InviteCreateOneOf1ToJson(InviteCreateOneOf1 instance) =>
    <String, dynamic>{
      'rail': _$InviteCreateOneOf1RailEnumEnumMap[instance.rail]!,
    };

const _$InviteCreateOneOf1RailEnumEnumMap = {
  InviteCreateOneOf1RailEnum.public: 'public',
};
