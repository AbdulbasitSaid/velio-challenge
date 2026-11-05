// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_goal.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminGoalCWProxy {
  AdminGoal id(AdminGoalIdEnum id);

  AdminGoal label(String label);

  AdminGoal unit(AdminGoalUnitEnum unit);

  AdminGoal value(num? value);

  AdminGoal target(num? target);

  AdminGoal trigger(String trigger);

  AdminGoal triggered(bool triggered);

  AdminGoal sample(int sample);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminGoal(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminGoal(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminGoal call({
    AdminGoalIdEnum id,
    String label,
    AdminGoalUnitEnum unit,
    num? value,
    num? target,
    String trigger,
    bool triggered,
    int sample,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminGoal.copyWith(...)` or call `instanceOfAdminGoal.copyWith.fieldName(value)` for a single field.
class _$AdminGoalCWProxyImpl implements _$AdminGoalCWProxy {
  const _$AdminGoalCWProxyImpl(this._value);

  final AdminGoal _value;

  @override
  AdminGoal id(AdminGoalIdEnum id) => call(id: id);

  @override
  AdminGoal label(String label) => call(label: label);

  @override
  AdminGoal unit(AdminGoalUnitEnum unit) => call(unit: unit);

  @override
  AdminGoal value(num? value) => call(value: value);

  @override
  AdminGoal target(num? target) => call(target: target);

  @override
  AdminGoal trigger(String trigger) => call(trigger: trigger);

  @override
  AdminGoal triggered(bool triggered) => call(triggered: triggered);

  @override
  AdminGoal sample(int sample) => call(sample: sample);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminGoal(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminGoal(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminGoal call({
    Object? id = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? unit = const $CopyWithPlaceholder(),
    Object? value = const $CopyWithPlaceholder(),
    Object? target = const $CopyWithPlaceholder(),
    Object? trigger = const $CopyWithPlaceholder(),
    Object? triggered = const $CopyWithPlaceholder(),
    Object? sample = const $CopyWithPlaceholder(),
  }) {
    return AdminGoal(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as AdminGoalIdEnum,
      label: label == const $CopyWithPlaceholder() || label == null
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      unit: unit == const $CopyWithPlaceholder() || unit == null
          ? _value.unit
          // ignore: cast_nullable_to_non_nullable
          : unit as AdminGoalUnitEnum,
      value: value == const $CopyWithPlaceholder()
          ? _value.value
          // ignore: cast_nullable_to_non_nullable
          : value as num?,
      target: target == const $CopyWithPlaceholder()
          ? _value.target
          // ignore: cast_nullable_to_non_nullable
          : target as num?,
      trigger: trigger == const $CopyWithPlaceholder() || trigger == null
          ? _value.trigger
          // ignore: cast_nullable_to_non_nullable
          : trigger as String,
      triggered: triggered == const $CopyWithPlaceholder() || triggered == null
          ? _value.triggered
          // ignore: cast_nullable_to_non_nullable
          : triggered as bool,
      sample: sample == const $CopyWithPlaceholder() || sample == null
          ? _value.sample
          // ignore: cast_nullable_to_non_nullable
          : sample as int,
    );
  }
}

extension $AdminGoalCopyWith on AdminGoal {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminGoal.copyWith(...)` or `instanceOfAdminGoal.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminGoalCWProxy get copyWith => _$AdminGoalCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminGoal _$AdminGoalFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminGoal', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'label',
          'unit',
          'value',
          'target',
          'trigger',
          'triggered',
          'sample',
        ],
      );
      final val = AdminGoal(
        id: $checkedConvert(
          'id',
          (v) => $enumDecode(_$AdminGoalIdEnumEnumMap, v),
        ),
        label: $checkedConvert('label', (v) => v as String),
        unit: $checkedConvert(
          'unit',
          (v) => $enumDecode(_$AdminGoalUnitEnumEnumMap, v),
        ),
        value: $checkedConvert('value', (v) => v as num?),
        target: $checkedConvert('target', (v) => v as num?),
        trigger: $checkedConvert('trigger', (v) => v as String),
        triggered: $checkedConvert('triggered', (v) => v as bool),
        sample: $checkedConvert('sample', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$AdminGoalToJson(AdminGoal instance) => <String, dynamic>{
  'id': _$AdminGoalIdEnumEnumMap[instance.id]!,
  'label': instance.label,
  'unit': _$AdminGoalUnitEnumEnumMap[instance.unit]!,
  'value': instance.value,
  'target': instance.target,
  'trigger': instance.trigger,
  'triggered': instance.triggered,
  'sample': instance.sample,
};

const _$AdminGoalIdEnumEnumMap = {
  AdminGoalIdEnum.noOversell: 'no_oversell',
  AdminGoalIdEnum.bookingSuccess: 'booking_success',
  AdminGoalIdEnum.availabilityLive: 'availability_live',
  AdminGoalIdEnum.bookersInvite: 'bookers_invite',
  AdminGoalIdEnum.invitesConvertVouch: 'invites_convert_vouch',
  AdminGoalIdEnum.invitesConvertPublic: 'invites_convert_public',
};

const _$AdminGoalUnitEnumEnumMap = {
  AdminGoalUnitEnum.count: 'count',
  AdminGoalUnitEnum.ratio: 'ratio',
  AdminGoalUnitEnum.seconds: 'seconds',
};
