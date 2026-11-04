// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_view_activity.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlanViewActivityCWProxy {
  PlanViewActivity id(String id);

  PlanViewActivity title(String title);

  PlanViewActivity startsAt(DateTime startsAt);

  PlanViewActivity timezone(String timezone);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlanViewActivity(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlanViewActivity(...).copyWith(id: 12, name: "My name")
  /// ```
  PlanViewActivity call({
    String id,
    String title,
    DateTime startsAt,
    String timezone,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPlanViewActivity.copyWith(...)` or call `instanceOfPlanViewActivity.copyWith.fieldName(value)` for a single field.
class _$PlanViewActivityCWProxyImpl implements _$PlanViewActivityCWProxy {
  const _$PlanViewActivityCWProxyImpl(this._value);

  final PlanViewActivity _value;

  @override
  PlanViewActivity id(String id) => call(id: id);

  @override
  PlanViewActivity title(String title) => call(title: title);

  @override
  PlanViewActivity startsAt(DateTime startsAt) => call(startsAt: startsAt);

  @override
  PlanViewActivity timezone(String timezone) => call(timezone: timezone);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlanViewActivity(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlanViewActivity(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PlanViewActivity call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? startsAt = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
  }) {
    return PlanViewActivity(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      startsAt: startsAt == const $CopyWithPlaceholder() || startsAt == null
          ? _value.startsAt
          // ignore: cast_nullable_to_non_nullable
          : startsAt as DateTime,
      timezone: timezone == const $CopyWithPlaceholder() || timezone == null
          ? _value.timezone
          // ignore: cast_nullable_to_non_nullable
          : timezone as String,
    );
  }
}

extension $PlanViewActivityCopyWith on PlanViewActivity {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPlanViewActivity.copyWith(...)` or `instanceOfPlanViewActivity.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlanViewActivityCWProxy get copyWith => _$PlanViewActivityCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanViewActivity _$PlanViewActivityFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PlanViewActivity', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'title', 'startsAt', 'timezone']);
  final val = PlanViewActivity(
    id: $checkedConvert('id', (v) => v as String),
    title: $checkedConvert('title', (v) => v as String),
    startsAt: $checkedConvert('startsAt', (v) => DateTime.parse(v as String)),
    timezone: $checkedConvert('timezone', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$PlanViewActivityToJson(PlanViewActivity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'startsAt': instance.startsAt.toIso8601String(),
      'timezone': instance.timezone,
    };
