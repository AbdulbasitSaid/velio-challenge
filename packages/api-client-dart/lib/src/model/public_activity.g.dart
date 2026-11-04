// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_activity.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicActivityCWProxy {
  PublicActivity id(String id);

  PublicActivity title(String title);

  PublicActivity description(String description);

  PublicActivity photoUrl(String? photoUrl);

  PublicActivity startsAt(DateTime startsAt);

  PublicActivity timezone(String timezone);

  PublicActivity priceMinor(int priceMinor);

  PublicActivity currency(String currency);

  PublicActivity capacity(int capacity);

  PublicActivity spotsLeft(int spotsLeft);

  PublicActivity version(int version);

  PublicActivity status(PublicActivityStatusEnum status);

  PublicActivity bookingsPaused(bool bookingsPaused);

  PublicActivity host(PublicPerson host);

  PublicActivity community(PublicActivityCommunity community);

  PublicActivity members(PublicActivityMembers members);

  PublicActivity location(PublicLocation location);

  PublicActivity viewer(PublicActivityViewer? viewer);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicActivity(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicActivity(...).copyWith(id: 12, name: "My name")
  /// ```
  PublicActivity call({
    String id,
    String title,
    String description,
    String? photoUrl,
    DateTime startsAt,
    String timezone,
    int priceMinor,
    String currency,
    int capacity,
    int spotsLeft,
    int version,
    PublicActivityStatusEnum status,
    bool bookingsPaused,
    PublicPerson host,
    PublicActivityCommunity community,
    PublicActivityMembers members,
    PublicLocation location,
    PublicActivityViewer? viewer,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPublicActivity.copyWith(...)` or call `instanceOfPublicActivity.copyWith.fieldName(value)` for a single field.
class _$PublicActivityCWProxyImpl implements _$PublicActivityCWProxy {
  const _$PublicActivityCWProxyImpl(this._value);

  final PublicActivity _value;

  @override
  PublicActivity id(String id) => call(id: id);

  @override
  PublicActivity title(String title) => call(title: title);

  @override
  PublicActivity description(String description) =>
      call(description: description);

  @override
  PublicActivity photoUrl(String? photoUrl) => call(photoUrl: photoUrl);

  @override
  PublicActivity startsAt(DateTime startsAt) => call(startsAt: startsAt);

  @override
  PublicActivity timezone(String timezone) => call(timezone: timezone);

  @override
  PublicActivity priceMinor(int priceMinor) => call(priceMinor: priceMinor);

  @override
  PublicActivity currency(String currency) => call(currency: currency);

  @override
  PublicActivity capacity(int capacity) => call(capacity: capacity);

  @override
  PublicActivity spotsLeft(int spotsLeft) => call(spotsLeft: spotsLeft);

  @override
  PublicActivity version(int version) => call(version: version);

  @override
  PublicActivity status(PublicActivityStatusEnum status) =>
      call(status: status);

  @override
  PublicActivity bookingsPaused(bool bookingsPaused) =>
      call(bookingsPaused: bookingsPaused);

  @override
  PublicActivity host(PublicPerson host) => call(host: host);

  @override
  PublicActivity community(PublicActivityCommunity community) =>
      call(community: community);

  @override
  PublicActivity members(PublicActivityMembers members) =>
      call(members: members);

  @override
  PublicActivity location(PublicLocation location) => call(location: location);

  @override
  PublicActivity viewer(PublicActivityViewer? viewer) => call(viewer: viewer);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicActivity(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicActivity(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PublicActivity call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? photoUrl = const $CopyWithPlaceholder(),
    Object? startsAt = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
    Object? priceMinor = const $CopyWithPlaceholder(),
    Object? currency = const $CopyWithPlaceholder(),
    Object? capacity = const $CopyWithPlaceholder(),
    Object? spotsLeft = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? bookingsPaused = const $CopyWithPlaceholder(),
    Object? host = const $CopyWithPlaceholder(),
    Object? community = const $CopyWithPlaceholder(),
    Object? members = const $CopyWithPlaceholder(),
    Object? location = const $CopyWithPlaceholder(),
    Object? viewer = const $CopyWithPlaceholder(),
  }) {
    return PublicActivity(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      photoUrl: photoUrl == const $CopyWithPlaceholder()
          ? _value.photoUrl
          // ignore: cast_nullable_to_non_nullable
          : photoUrl as String?,
      startsAt: startsAt == const $CopyWithPlaceholder() || startsAt == null
          ? _value.startsAt
          // ignore: cast_nullable_to_non_nullable
          : startsAt as DateTime,
      timezone: timezone == const $CopyWithPlaceholder() || timezone == null
          ? _value.timezone
          // ignore: cast_nullable_to_non_nullable
          : timezone as String,
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
      spotsLeft: spotsLeft == const $CopyWithPlaceholder() || spotsLeft == null
          ? _value.spotsLeft
          // ignore: cast_nullable_to_non_nullable
          : spotsLeft as int,
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as PublicActivityStatusEnum,
      bookingsPaused:
          bookingsPaused == const $CopyWithPlaceholder() ||
              bookingsPaused == null
          ? _value.bookingsPaused
          // ignore: cast_nullable_to_non_nullable
          : bookingsPaused as bool,
      host: host == const $CopyWithPlaceholder() || host == null
          ? _value.host
          // ignore: cast_nullable_to_non_nullable
          : host as PublicPerson,
      community: community == const $CopyWithPlaceholder() || community == null
          ? _value.community
          // ignore: cast_nullable_to_non_nullable
          : community as PublicActivityCommunity,
      members: members == const $CopyWithPlaceholder() || members == null
          ? _value.members
          // ignore: cast_nullable_to_non_nullable
          : members as PublicActivityMembers,
      location: location == const $CopyWithPlaceholder() || location == null
          ? _value.location
          // ignore: cast_nullable_to_non_nullable
          : location as PublicLocation,
      viewer: viewer == const $CopyWithPlaceholder()
          ? _value.viewer
          // ignore: cast_nullable_to_non_nullable
          : viewer as PublicActivityViewer?,
    );
  }
}

extension $PublicActivityCopyWith on PublicActivity {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPublicActivity.copyWith(...)` or `instanceOfPublicActivity.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicActivityCWProxy get copyWith => _$PublicActivityCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicActivity _$PublicActivityFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PublicActivity', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'title',
          'description',
          'photoUrl',
          'startsAt',
          'timezone',
          'priceMinor',
          'currency',
          'capacity',
          'spotsLeft',
          'version',
          'status',
          'bookingsPaused',
          'host',
          'community',
          'members',
          'location',
          'viewer',
        ],
      );
      final val = PublicActivity(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        photoUrl: $checkedConvert('photoUrl', (v) => v as String?),
        startsAt: $checkedConvert(
          'startsAt',
          (v) => DateTime.parse(v as String),
        ),
        timezone: $checkedConvert('timezone', (v) => v as String),
        priceMinor: $checkedConvert('priceMinor', (v) => (v as num).toInt()),
        currency: $checkedConvert('currency', (v) => v as String),
        capacity: $checkedConvert('capacity', (v) => (v as num).toInt()),
        spotsLeft: $checkedConvert('spotsLeft', (v) => (v as num).toInt()),
        version: $checkedConvert('version', (v) => (v as num).toInt()),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$PublicActivityStatusEnumEnumMap, v),
        ),
        bookingsPaused: $checkedConvert('bookingsPaused', (v) => v as bool),
        host: $checkedConvert(
          'host',
          (v) => PublicPerson.fromJson(v as Map<String, dynamic>),
        ),
        community: $checkedConvert(
          'community',
          (v) => PublicActivityCommunity.fromJson(v as Map<String, dynamic>),
        ),
        members: $checkedConvert(
          'members',
          (v) => PublicActivityMembers.fromJson(v as Map<String, dynamic>),
        ),
        location: $checkedConvert(
          'location',
          (v) => PublicLocation.fromJson(v as Map<String, dynamic>),
        ),
        viewer: $checkedConvert(
          'viewer',
          (v) => v == null
              ? null
              : PublicActivityViewer.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PublicActivityToJson(PublicActivity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'photoUrl': instance.photoUrl,
      'startsAt': instance.startsAt.toIso8601String(),
      'timezone': instance.timezone,
      'priceMinor': instance.priceMinor,
      'currency': instance.currency,
      'capacity': instance.capacity,
      'spotsLeft': instance.spotsLeft,
      'version': instance.version,
      'status': _$PublicActivityStatusEnumEnumMap[instance.status]!,
      'bookingsPaused': instance.bookingsPaused,
      'host': instance.host.toJson(),
      'community': instance.community.toJson(),
      'members': instance.members.toJson(),
      'location': instance.location.toJson(),
      'viewer': instance.viewer?.toJson(),
    };

const _$PublicActivityStatusEnumEnumMap = {
  PublicActivityStatusEnum.open: 'open',
  PublicActivityStatusEnum.soldOut: 'sold_out',
  PublicActivityStatusEnum.started: 'started',
};
