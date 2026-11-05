// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_activity.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AdminActivityCWProxy {
  AdminActivity id(String id);

  AdminActivity title(String title);

  AdminActivity communityName(String communityName);

  AdminActivity startsAt(DateTime startsAt);

  AdminActivity timezone(String timezone);

  AdminActivity capacity(int capacity);

  AdminActivity spotsLeft(int spotsLeft);

  AdminActivity bookingsPaused(bool bookingsPaused);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminActivity(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminActivity(...).copyWith(id: 12, name: "My name")
  /// ```
  AdminActivity call({
    String id,
    String title,
    String communityName,
    DateTime startsAt,
    String timezone,
    int capacity,
    int spotsLeft,
    bool bookingsPaused,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAdminActivity.copyWith(...)` or call `instanceOfAdminActivity.copyWith.fieldName(value)` for a single field.
class _$AdminActivityCWProxyImpl implements _$AdminActivityCWProxy {
  const _$AdminActivityCWProxyImpl(this._value);

  final AdminActivity _value;

  @override
  AdminActivity id(String id) => call(id: id);

  @override
  AdminActivity title(String title) => call(title: title);

  @override
  AdminActivity communityName(String communityName) =>
      call(communityName: communityName);

  @override
  AdminActivity startsAt(DateTime startsAt) => call(startsAt: startsAt);

  @override
  AdminActivity timezone(String timezone) => call(timezone: timezone);

  @override
  AdminActivity capacity(int capacity) => call(capacity: capacity);

  @override
  AdminActivity spotsLeft(int spotsLeft) => call(spotsLeft: spotsLeft);

  @override
  AdminActivity bookingsPaused(bool bookingsPaused) =>
      call(bookingsPaused: bookingsPaused);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AdminActivity(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AdminActivity(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AdminActivity call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? communityName = const $CopyWithPlaceholder(),
    Object? startsAt = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
    Object? capacity = const $CopyWithPlaceholder(),
    Object? spotsLeft = const $CopyWithPlaceholder(),
    Object? bookingsPaused = const $CopyWithPlaceholder(),
  }) {
    return AdminActivity(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      communityName:
          communityName == const $CopyWithPlaceholder() || communityName == null
          ? _value.communityName
          // ignore: cast_nullable_to_non_nullable
          : communityName as String,
      startsAt: startsAt == const $CopyWithPlaceholder() || startsAt == null
          ? _value.startsAt
          // ignore: cast_nullable_to_non_nullable
          : startsAt as DateTime,
      timezone: timezone == const $CopyWithPlaceholder() || timezone == null
          ? _value.timezone
          // ignore: cast_nullable_to_non_nullable
          : timezone as String,
      capacity: capacity == const $CopyWithPlaceholder() || capacity == null
          ? _value.capacity
          // ignore: cast_nullable_to_non_nullable
          : capacity as int,
      spotsLeft: spotsLeft == const $CopyWithPlaceholder() || spotsLeft == null
          ? _value.spotsLeft
          // ignore: cast_nullable_to_non_nullable
          : spotsLeft as int,
      bookingsPaused:
          bookingsPaused == const $CopyWithPlaceholder() ||
              bookingsPaused == null
          ? _value.bookingsPaused
          // ignore: cast_nullable_to_non_nullable
          : bookingsPaused as bool,
    );
  }
}

extension $AdminActivityCopyWith on AdminActivity {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAdminActivity.copyWith(...)` or `instanceOfAdminActivity.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AdminActivityCWProxy get copyWith => _$AdminActivityCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminActivity _$AdminActivityFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AdminActivity', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'title',
          'communityName',
          'startsAt',
          'timezone',
          'capacity',
          'spotsLeft',
          'bookingsPaused',
        ],
      );
      final val = AdminActivity(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        communityName: $checkedConvert('communityName', (v) => v as String),
        startsAt: $checkedConvert(
          'startsAt',
          (v) => DateTime.parse(v as String),
        ),
        timezone: $checkedConvert('timezone', (v) => v as String),
        capacity: $checkedConvert('capacity', (v) => (v as num).toInt()),
        spotsLeft: $checkedConvert('spotsLeft', (v) => (v as num).toInt()),
        bookingsPaused: $checkedConvert('bookingsPaused', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$AdminActivityToJson(AdminActivity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'communityName': instance.communityName,
      'startsAt': instance.startsAt.toIso8601String(),
      'timezone': instance.timezone,
      'capacity': instance.capacity,
      'spotsLeft': instance.spotsLeft,
      'bookingsPaused': instance.bookingsPaused,
    };
