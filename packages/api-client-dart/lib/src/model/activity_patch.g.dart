// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_patch.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ActivityPatchCWProxy {
  ActivityPatch title(String? title);

  ActivityPatch description(String? description);

  ActivityPatch startsAt(DateTime? startsAt);

  ActivityPatch timezone(String? timezone);

  ActivityPatch location(Location? location);

  ActivityPatch capacity(int? capacity);

  ActivityPatch photoKey(String? photoKey);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActivityPatch(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActivityPatch(...).copyWith(id: 12, name: "My name")
  /// ```
  ActivityPatch call({
    String? title,
    String? description,
    DateTime? startsAt,
    String? timezone,
    Location? location,
    int? capacity,
    String? photoKey,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfActivityPatch.copyWith(...)` or call `instanceOfActivityPatch.copyWith.fieldName(value)` for a single field.
class _$ActivityPatchCWProxyImpl implements _$ActivityPatchCWProxy {
  const _$ActivityPatchCWProxyImpl(this._value);

  final ActivityPatch _value;

  @override
  ActivityPatch title(String? title) => call(title: title);

  @override
  ActivityPatch description(String? description) =>
      call(description: description);

  @override
  ActivityPatch startsAt(DateTime? startsAt) => call(startsAt: startsAt);

  @override
  ActivityPatch timezone(String? timezone) => call(timezone: timezone);

  @override
  ActivityPatch location(Location? location) => call(location: location);

  @override
  ActivityPatch capacity(int? capacity) => call(capacity: capacity);

  @override
  ActivityPatch photoKey(String? photoKey) => call(photoKey: photoKey);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActivityPatch(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActivityPatch(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ActivityPatch call({
    Object? title = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? startsAt = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
    Object? location = const $CopyWithPlaceholder(),
    Object? capacity = const $CopyWithPlaceholder(),
    Object? photoKey = const $CopyWithPlaceholder(),
  }) {
    return ActivityPatch(
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
      startsAt: startsAt == const $CopyWithPlaceholder()
          ? _value.startsAt
          // ignore: cast_nullable_to_non_nullable
          : startsAt as DateTime?,
      timezone: timezone == const $CopyWithPlaceholder()
          ? _value.timezone
          // ignore: cast_nullable_to_non_nullable
          : timezone as String?,
      location: location == const $CopyWithPlaceholder()
          ? _value.location
          // ignore: cast_nullable_to_non_nullable
          : location as Location?,
      capacity: capacity == const $CopyWithPlaceholder()
          ? _value.capacity
          // ignore: cast_nullable_to_non_nullable
          : capacity as int?,
      photoKey: photoKey == const $CopyWithPlaceholder()
          ? _value.photoKey
          // ignore: cast_nullable_to_non_nullable
          : photoKey as String?,
    );
  }
}

extension $ActivityPatchCopyWith on ActivityPatch {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfActivityPatch.copyWith(...)` or `instanceOfActivityPatch.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ActivityPatchCWProxy get copyWith => _$ActivityPatchCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityPatch _$ActivityPatchFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ActivityPatch', json, ($checkedConvert) {
      final val = ActivityPatch(
        title: $checkedConvert('title', (v) => v as String?),
        description: $checkedConvert('description', (v) => v as String?),
        startsAt: $checkedConvert(
          'startsAt',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
        timezone: $checkedConvert('timezone', (v) => v as String?),
        location: $checkedConvert(
          'location',
          (v) =>
              v == null ? null : Location.fromJson(v as Map<String, dynamic>),
        ),
        capacity: $checkedConvert('capacity', (v) => (v as num?)?.toInt()),
        photoKey: $checkedConvert('photoKey', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ActivityPatchToJson(ActivityPatch instance) =>
    <String, dynamic>{
      'title': ?instance.title,
      'description': ?instance.description,
      'startsAt': ?instance.startsAt?.toIso8601String(),
      'timezone': ?instance.timezone,
      'location': ?instance.location?.toJson(),
      'capacity': ?instance.capacity,
      'photoKey': ?instance.photoKey,
    };
