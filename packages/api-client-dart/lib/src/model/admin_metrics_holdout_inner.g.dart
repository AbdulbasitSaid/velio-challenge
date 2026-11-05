// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_metrics_holdout_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminMetricsHoldoutInnerCWProxy {
  AdminMetricsHoldoutInner arm(AdminMetricsHoldoutInnerArmEnum arm);

  AdminMetricsHoldoutInner users(int users);

  AdminMetricsHoldoutInner bookers(int bookers);

  AdminMetricsHoldoutInner newUsersPerBooker(Ratio newUsersPerBooker);

  AdminMetricsHoldoutInner plansHappened(Ratio plansHappened);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMetricsHoldoutInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMetricsHoldoutInner(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminMetricsHoldoutInner call({
    AdminMetricsHoldoutInnerArmEnum arm,
    int users,
    int bookers,
    Ratio newUsersPerBooker,
    Ratio plansHappened,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminMetricsHoldoutInner.copyWith(...)` or call `instanceOfAdminMetricsHoldoutInner.copyWith.fieldName(value)` for a single field.
class _$AdminMetricsHoldoutInnerCWProxyImpl
    implements _$AdminMetricsHoldoutInnerCWProxy {
  const _$AdminMetricsHoldoutInnerCWProxyImpl(this._value);

  final AdminMetricsHoldoutInner _value;

  @override
  AdminMetricsHoldoutInner arm(AdminMetricsHoldoutInnerArmEnum arm) =>
      call(arm: arm);

  @override
  AdminMetricsHoldoutInner users(int users) => call(users: users);

  @override
  AdminMetricsHoldoutInner bookers(int bookers) => call(bookers: bookers);

  @override
  AdminMetricsHoldoutInner newUsersPerBooker(Ratio newUsersPerBooker) =>
      call(newUsersPerBooker: newUsersPerBooker);

  @override
  AdminMetricsHoldoutInner plansHappened(Ratio plansHappened) =>
      call(plansHappened: plansHappened);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminMetricsHoldoutInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminMetricsHoldoutInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminMetricsHoldoutInner call({
    Object? arm = const $CopyWithPlaceholder(),
    Object? users = const $CopyWithPlaceholder(),
    Object? bookers = const $CopyWithPlaceholder(),
    Object? newUsersPerBooker = const $CopyWithPlaceholder(),
    Object? plansHappened = const $CopyWithPlaceholder(),
  }) {
    return AdminMetricsHoldoutInner(
      arm: arm == const $CopyWithPlaceholder() || arm == null
          ? _value.arm
          // ignore: cast_nullable_to_non_nullable
          : arm as AdminMetricsHoldoutInnerArmEnum,
      users: users == const $CopyWithPlaceholder() || users == null
          ? _value.users
          // ignore: cast_nullable_to_non_nullable
          : users as int,
      bookers: bookers == const $CopyWithPlaceholder() || bookers == null
          ? _value.bookers
          // ignore: cast_nullable_to_non_nullable
          : bookers as int,
      newUsersPerBooker:
          newUsersPerBooker == const $CopyWithPlaceholder() ||
              newUsersPerBooker == null
          ? _value.newUsersPerBooker
          // ignore: cast_nullable_to_non_nullable
          : newUsersPerBooker as Ratio,
      plansHappened:
          plansHappened == const $CopyWithPlaceholder() || plansHappened == null
          ? _value.plansHappened
          // ignore: cast_nullable_to_non_nullable
          : plansHappened as Ratio,
    );
  }
}

extension $AdminMetricsHoldoutInnerCopyWith on AdminMetricsHoldoutInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminMetricsHoldoutInner.copyWith(...)` or `instanceOfAdminMetricsHoldoutInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminMetricsHoldoutInnerCWProxy get copyWith =>
      _$AdminMetricsHoldoutInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminMetricsHoldoutInner _$AdminMetricsHoldoutInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AdminMetricsHoldoutInner', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const [
      'arm',
      'users',
      'bookers',
      'newUsersPerBooker',
      'plansHappened',
    ],
  );
  final val = AdminMetricsHoldoutInner(
    arm: $checkedConvert(
      'arm',
      (v) => $enumDecode(_$AdminMetricsHoldoutInnerArmEnumEnumMap, v),
    ),
    users: $checkedConvert('users', (v) => (v as num).toInt()),
    bookers: $checkedConvert('bookers', (v) => (v as num).toInt()),
    newUsersPerBooker: $checkedConvert(
      'newUsersPerBooker',
      (v) => Ratio.fromJson(v as Map<String, dynamic>),
    ),
    plansHappened: $checkedConvert(
      'plansHappened',
      (v) => Ratio.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$AdminMetricsHoldoutInnerToJson(
  AdminMetricsHoldoutInner instance,
) => <String, dynamic>{
  'arm': _$AdminMetricsHoldoutInnerArmEnumEnumMap[instance.arm]!,
  'users': instance.users,
  'bookers': instance.bookers,
  'newUsersPerBooker': instance.newUsersPerBooker.toJson(),
  'plansHappened': instance.plansHappened.toJson(),
};

const _$AdminMetricsHoldoutInnerArmEnumEnumMap = {
  AdminMetricsHoldoutInnerArmEnum.exposed: 'exposed',
  AdminMetricsHoldoutInnerArmEnum.holdout: 'holdout',
};
