// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_activity_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminActivityListCWProxy {
  AdminActivityList activities(List<AdminActivity> activities);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminActivityList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminActivityList(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminActivityList call({List<AdminActivity> activities});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminActivityList.copyWith(...)` or call `instanceOfAdminActivityList.copyWith.fieldName(value)` for a single field.
class _$AdminActivityListCWProxyImpl implements _$AdminActivityListCWProxy {
  const _$AdminActivityListCWProxyImpl(this._value);

  final AdminActivityList _value;

  @override
  AdminActivityList activities(List<AdminActivity> activities) =>
      call(activities: activities);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminActivityList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminActivityList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminActivityList call({Object? activities = const $CopyWithPlaceholder()}) {
    return AdminActivityList(
      activities:
          activities == const $CopyWithPlaceholder() || activities == null
          ? _value.activities
          // ignore: cast_nullable_to_non_nullable
          : activities as List<AdminActivity>,
    );
  }
}

extension $AdminActivityListCopyWith on AdminActivityList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminActivityList.copyWith(...)` or `instanceOfAdminActivityList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminActivityListCWProxy get copyWith =>
      _$AdminActivityListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminActivityList _$AdminActivityListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminActivityList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['activities']);
      final val = AdminActivityList(
        activities: $checkedConvert(
          'activities',
          (v) => (v as List<dynamic>)
              .map((e) => AdminActivity.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$AdminActivityListToJson(AdminActivityList instance) =>
    <String, dynamic>{
      'activities': instance.activities.map((e) => e.toJson()).toList(),
    };
