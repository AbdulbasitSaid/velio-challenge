// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'host_activity_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$HostActivityListCWProxy {
  HostActivityList upcoming(List<HostActivityItem> upcoming);

  HostActivityList past(List<HostActivityItem> past);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `HostActivityList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// HostActivityList(...).copyWith(id: 12, name: "My name")
  /// ```
  HostActivityList call({
    List<HostActivityItem> upcoming,
    List<HostActivityItem> past,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfHostActivityList.copyWith(...)` or call `instanceOfHostActivityList.copyWith.fieldName(value)` for a single field.
class _$HostActivityListCWProxyImpl implements _$HostActivityListCWProxy {
  const _$HostActivityListCWProxyImpl(this._value);

  final HostActivityList _value;

  @override
  HostActivityList upcoming(List<HostActivityItem> upcoming) =>
      call(upcoming: upcoming);

  @override
  HostActivityList past(List<HostActivityItem> past) => call(past: past);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `HostActivityList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// HostActivityList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  HostActivityList call({
    Object? upcoming = const $CopyWithPlaceholder(),
    Object? past = const $CopyWithPlaceholder(),
  }) {
    return HostActivityList(
      upcoming: upcoming == const $CopyWithPlaceholder() || upcoming == null
          ? _value.upcoming
          // ignore: cast_nullable_to_non_nullable
          : upcoming as List<HostActivityItem>,
      past: past == const $CopyWithPlaceholder() || past == null
          ? _value.past
          // ignore: cast_nullable_to_non_nullable
          : past as List<HostActivityItem>,
    );
  }
}

extension $HostActivityListCopyWith on HostActivityList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfHostActivityList.copyWith(...)` or `instanceOfHostActivityList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$HostActivityListCWProxy get copyWith => _$HostActivityListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HostActivityList _$HostActivityListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HostActivityList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['upcoming', 'past']);
      final val = HostActivityList(
        upcoming: $checkedConvert(
          'upcoming',
          (v) => (v as List<dynamic>)
              .map((e) => HostActivityItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        past: $checkedConvert(
          'past',
          (v) => (v as List<dynamic>)
              .map((e) => HostActivityItem.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HostActivityListToJson(HostActivityList instance) =>
    <String, dynamic>{
      'upcoming': instance.upcoming.map((e) => e.toJson()).toList(),
      'past': instance.past.map((e) => e.toJson()).toList(),
    };
