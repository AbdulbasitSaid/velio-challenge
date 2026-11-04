// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_plans.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MyPlansCWProxy {
  MyPlans upcoming(List<MyPlan> upcoming);

  MyPlans past(List<MyPlan> past);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MyPlans(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MyPlans(...).copyWith(id: 12, name: "My name")
  /// ```
  MyPlans call({List<MyPlan> upcoming, List<MyPlan> past});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMyPlans.copyWith(...)` or call `instanceOfMyPlans.copyWith.fieldName(value)` for a single field.
class _$MyPlansCWProxyImpl implements _$MyPlansCWProxy {
  const _$MyPlansCWProxyImpl(this._value);

  final MyPlans _value;

  @override
  MyPlans upcoming(List<MyPlan> upcoming) => call(upcoming: upcoming);

  @override
  MyPlans past(List<MyPlan> past) => call(past: past);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MyPlans(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MyPlans(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MyPlans call({
    Object? upcoming = const $CopyWithPlaceholder(),
    Object? past = const $CopyWithPlaceholder(),
  }) {
    return MyPlans(
      upcoming: upcoming == const $CopyWithPlaceholder() || upcoming == null
          ? _value.upcoming
          // ignore: cast_nullable_to_non_nullable
          : upcoming as List<MyPlan>,
      past: past == const $CopyWithPlaceholder() || past == null
          ? _value.past
          // ignore: cast_nullable_to_non_nullable
          : past as List<MyPlan>,
    );
  }
}

extension $MyPlansCopyWith on MyPlans {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMyPlans.copyWith(...)` or `instanceOfMyPlans.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MyPlansCWProxy get copyWith => _$MyPlansCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyPlans _$MyPlansFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MyPlans', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['upcoming', 'past']);
      final val = MyPlans(
        upcoming: $checkedConvert(
          'upcoming',
          (v) => (v as List<dynamic>)
              .map((e) => MyPlan.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        past: $checkedConvert(
          'past',
          (v) => (v as List<dynamic>)
              .map((e) => MyPlan.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$MyPlansToJson(MyPlans instance) => <String, dynamic>{
  'upcoming': instance.upcoming.map((e) => e.toJson()).toList(),
  'past': instance.past.map((e) => e.toJson()).toList(),
};
