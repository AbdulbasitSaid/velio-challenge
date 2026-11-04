// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_create.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ActivityCreateCWProxy {
  ActivityCreate communitySlug(String communitySlug);

  ActivityCreate title(String title);

  ActivityCreate description(String? description);

  ActivityCreate startsAt(DateTime startsAt);

  ActivityCreate timezone(String timezone);

  ActivityCreate location(Location location);

  ActivityCreate priceMinor(int priceMinor);

  ActivityCreate currency(String currency);

  ActivityCreate capacity(int capacity);

  ActivityCreate photoKey(String? photoKey);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActivityCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActivityCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  ActivityCreate call({
    String communitySlug,
    String title,
    String? description,
    DateTime startsAt,
    String timezone,
    Location location,
    int priceMinor,
    String currency,
    int capacity,
    String? photoKey,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfActivityCreate.copyWith(...)` or call `instanceOfActivityCreate.copyWith.fieldName(value)` for a single field.
class _$ActivityCreateCWProxyImpl implements _$ActivityCreateCWProxy {
  const _$ActivityCreateCWProxyImpl(this._value);

  final ActivityCreate _value;

  @override
  ActivityCreate communitySlug(String communitySlug) =>
      call(communitySlug: communitySlug);

  @override
  ActivityCreate title(String title) => call(title: title);

  @override
  ActivityCreate description(String? description) =>
      call(description: description);

  @override
  ActivityCreate startsAt(DateTime startsAt) => call(startsAt: startsAt);

  @override
  ActivityCreate timezone(String timezone) => call(timezone: timezone);

  @override
  ActivityCreate location(Location location) => call(location: location);

  @override
  ActivityCreate priceMinor(int priceMinor) => call(priceMinor: priceMinor);

  @override
  ActivityCreate currency(String currency) => call(currency: currency);

  @override
  ActivityCreate capacity(int capacity) => call(capacity: capacity);

  @override
  ActivityCreate photoKey(String? photoKey) => call(photoKey: photoKey);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActivityCreate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActivityCreate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ActivityCreate call({
    Object? communitySlug = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? startsAt = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
    Object? location = const $CopyWithPlaceholder(),
    Object? priceMinor = const $CopyWithPlaceholder(),
    Object? currency = const $CopyWithPlaceholder(),
    Object? capacity = const $CopyWithPlaceholder(),
    Object? photoKey = const $CopyWithPlaceholder(),
  }) {
    return ActivityCreate(
      communitySlug:
          communitySlug == const $CopyWithPlaceholder() || communitySlug == null
          ? _value.communitySlug
          // ignore: cast_nullable_to_non_nullable
          : communitySlug as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
      startsAt: startsAt == const $CopyWithPlaceholder() || startsAt == null
          ? _value.startsAt
          // ignore: cast_nullable_to_non_nullable
          : startsAt as DateTime,
      timezone: timezone == const $CopyWithPlaceholder() || timezone == null
          ? _value.timezone
          // ignore: cast_nullable_to_non_nullable
          : timezone as String,
      location: location == const $CopyWithPlaceholder() || location == null
          ? _value.location
          // ignore: cast_nullable_to_non_nullable
          : location as Location,
      priceMinor:
          priceMinor == const $CopyWithPlaceholder() || priceMinor == null
          ? _value.priceMinor
          // ignore: cast_nullable_to_non_nullable
          : priceMinor as int,
      currency: currency == const $CopyWithPlaceholder() || currency == null
          ? _value.currency
          // ignore: cast_nullable_to_non_nullable
          : currency as String,
      capacity: capacity == const $CopyWithPlaceholder() || capacity == null
          ? _value.capacity
          // ignore: cast_nullable_to_non_nullable
          : capacity as int,
      photoKey: photoKey == const $CopyWithPlaceholder()
          ? _value.photoKey
          // ignore: cast_nullable_to_non_nullable
          : photoKey as String?,
    );
  }
}

extension $ActivityCreateCopyWith on ActivityCreate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfActivityCreate.copyWith(...)` or `instanceOfActivityCreate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ActivityCreateCWProxy get copyWith => _$ActivityCreateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityCreate _$ActivityCreateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ActivityCreate', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'communitySlug',
          'title',
          'startsAt',
          'timezone',
          'location',
          'priceMinor',
          'currency',
          'capacity',
        ],
      );
      final val = ActivityCreate(
        communitySlug: $checkedConvert('communitySlug', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String?),
        startsAt: $checkedConvert(
          'startsAt',
          (v) => DateTime.parse(v as String),
        ),
        timezone: $checkedConvert('timezone', (v) => v as String),
        location: $checkedConvert(
          'location',
          (v) => Location.fromJson(v as Map<String, dynamic>),
        ),
        priceMinor: $checkedConvert('priceMinor', (v) => (v as num).toInt()),
        currency: $checkedConvert('currency', (v) => v as String),
        capacity: $checkedConvert('capacity', (v) => (v as num).toInt()),
        photoKey: $checkedConvert('photoKey', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ActivityCreateToJson(ActivityCreate instance) =>
    <String, dynamic>{
      'communitySlug': instance.communitySlug,
      'title': instance.title,
      'description': ?instance.description,
      'startsAt': instance.startsAt.toIso8601String(),
      'timezone': instance.timezone,
      'location': instance.location.toJson(),
      'priceMinor': instance.priceMinor,
      'currency': instance.currency,
      'capacity': instance.capacity,
      'photoKey': ?instance.photoKey,
    };
