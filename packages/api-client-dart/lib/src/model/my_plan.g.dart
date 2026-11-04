// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_plan.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MyPlanCWProxy {
  MyPlan planId(String planId);

  MyPlan activity(ActivityCard activity);

  MyPlan booking(PlanViewViewerBooking booking);

  MyPlan members(MyPlanMembers members);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MyPlan(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MyPlan(...).copyWith(id: 12, name: "My name")
  /// ```
  MyPlan call({
    String planId,
    ActivityCard activity,
    PlanViewViewerBooking booking,
    MyPlanMembers members,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMyPlan.copyWith(...)` or call `instanceOfMyPlan.copyWith.fieldName(value)` for a single field.
class _$MyPlanCWProxyImpl implements _$MyPlanCWProxy {
  const _$MyPlanCWProxyImpl(this._value);

  final MyPlan _value;

  @override
  MyPlan planId(String planId) => call(planId: planId);

  @override
  MyPlan activity(ActivityCard activity) => call(activity: activity);

  @override
  MyPlan booking(PlanViewViewerBooking booking) => call(booking: booking);

  @override
  MyPlan members(MyPlanMembers members) => call(members: members);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MyPlan(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MyPlan(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MyPlan call({
    Object? planId = const $CopyWithPlaceholder(),
    Object? activity = const $CopyWithPlaceholder(),
    Object? booking = const $CopyWithPlaceholder(),
    Object? members = const $CopyWithPlaceholder(),
  }) {
    return MyPlan(
      planId: planId == const $CopyWithPlaceholder() || planId == null
          ? _value.planId
          // ignore: cast_nullable_to_non_nullable
          : planId as String,
      activity: activity == const $CopyWithPlaceholder() || activity == null
          ? _value.activity
          // ignore: cast_nullable_to_non_nullable
          : activity as ActivityCard,
      booking: booking == const $CopyWithPlaceholder() || booking == null
          ? _value.booking
          // ignore: cast_nullable_to_non_nullable
          : booking as PlanViewViewerBooking,
      members: members == const $CopyWithPlaceholder() || members == null
          ? _value.members
          // ignore: cast_nullable_to_non_nullable
          : members as MyPlanMembers,
    );
  }
}

extension $MyPlanCopyWith on MyPlan {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMyPlan.copyWith(...)` or `instanceOfMyPlan.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MyPlanCWProxy get copyWith => _$MyPlanCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyPlan _$MyPlanFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MyPlan', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['planId', 'activity', 'booking', 'members'],
      );
      final val = MyPlan(
        planId: $checkedConvert('planId', (v) => v as String),
        activity: $checkedConvert(
          'activity',
          (v) => ActivityCard.fromJson(v as Map<String, dynamic>),
        ),
        booking: $checkedConvert(
          'booking',
          (v) => PlanViewViewerBooking.fromJson(v as Map<String, dynamic>),
        ),
        members: $checkedConvert(
          'members',
          (v) => MyPlanMembers.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$MyPlanToJson(MyPlan instance) => <String, dynamic>{
  'planId': instance.planId,
  'activity': instance.activity.toJson(),
  'booking': instance.booking.toJson(),
  'members': instance.members.toJson(),
};
