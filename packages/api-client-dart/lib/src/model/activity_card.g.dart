// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_card.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ActivityCardCWProxy {
  ActivityCard id(String id);

  ActivityCard title(String title);

  ActivityCard summary(String summary);

  ActivityCard startsAt(DateTime startsAt);

  ActivityCard timezone(String timezone);

  ActivityCard priceMinor(int priceMinor);

  ActivityCard currency(String currency);

  ActivityCard photoUrl(String? photoUrl);

  ActivityCard capacity(int capacity);

  ActivityCard spotsLeft(int spotsLeft);

  ActivityCard version(int version);

  ActivityCard status(ActivityCardStatusEnum status);

  ActivityCard community(PublicActivityCommunity community);

  ActivityCard location(ActivityCardLocation location);

  ActivityCard members(PublicActivityMembers members);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActivityCard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActivityCard(...).copyWith(id: 12, name: "My name")
  /// ```
  ActivityCard call({
    String id,
    String title,
    String summary,
    DateTime startsAt,
    String timezone,
    int priceMinor,
    String currency,
    String? photoUrl,
    int capacity,
    int spotsLeft,
    int version,
    ActivityCardStatusEnum status,
    PublicActivityCommunity community,
    ActivityCardLocation location,
    PublicActivityMembers members,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfActivityCard.copyWith(...)` or call `instanceOfActivityCard.copyWith.fieldName(value)` for a single field.
class _$ActivityCardCWProxyImpl implements _$ActivityCardCWProxy {
  const _$ActivityCardCWProxyImpl(this._value);

  final ActivityCard _value;

  @override
  ActivityCard id(String id) => call(id: id);

  @override
  ActivityCard title(String title) => call(title: title);

  @override
  ActivityCard summary(String summary) => call(summary: summary);

  @override
  ActivityCard startsAt(DateTime startsAt) => call(startsAt: startsAt);

  @override
  ActivityCard timezone(String timezone) => call(timezone: timezone);

  @override
  ActivityCard priceMinor(int priceMinor) => call(priceMinor: priceMinor);

  @override
  ActivityCard currency(String currency) => call(currency: currency);

  @override
  ActivityCard photoUrl(String? photoUrl) => call(photoUrl: photoUrl);

  @override
  ActivityCard capacity(int capacity) => call(capacity: capacity);

  @override
  ActivityCard spotsLeft(int spotsLeft) => call(spotsLeft: spotsLeft);

  @override
  ActivityCard version(int version) => call(version: version);

  @override
  ActivityCard status(ActivityCardStatusEnum status) => call(status: status);

  @override
  ActivityCard community(PublicActivityCommunity community) =>
      call(community: community);

  @override
  ActivityCard location(ActivityCardLocation location) =>
      call(location: location);

  @override
  ActivityCard members(PublicActivityMembers members) => call(members: members);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ActivityCard(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ActivityCard(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ActivityCard call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
    Object? startsAt = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
    Object? priceMinor = const $CopyWithPlaceholder(),
    Object? currency = const $CopyWithPlaceholder(),
    Object? photoUrl = const $CopyWithPlaceholder(),
    Object? capacity = const $CopyWithPlaceholder(),
    Object? spotsLeft = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? community = const $CopyWithPlaceholder(),
    Object? location = const $CopyWithPlaceholder(),
    Object? members = const $CopyWithPlaceholder(),
  }) {
    return ActivityCard(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      summary: summary == const $CopyWithPlaceholder() || summary == null
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as String,
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
      photoUrl: photoUrl == const $CopyWithPlaceholder()
          ? _value.photoUrl
          // ignore: cast_nullable_to_non_nullable
          : photoUrl as String?,
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
          : status as ActivityCardStatusEnum,
      community: community == const $CopyWithPlaceholder() || community == null
          ? _value.community
          // ignore: cast_nullable_to_non_nullable
          : community as PublicActivityCommunity,
      location: location == const $CopyWithPlaceholder() || location == null
          ? _value.location
          // ignore: cast_nullable_to_non_nullable
          : location as ActivityCardLocation,
      members: members == const $CopyWithPlaceholder() || members == null
          ? _value.members
          // ignore: cast_nullable_to_non_nullable
          : members as PublicActivityMembers,
    );
  }
}

extension $ActivityCardCopyWith on ActivityCard {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfActivityCard.copyWith(...)` or `instanceOfActivityCard.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ActivityCardCWProxy get copyWith => _$ActivityCardCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityCard _$ActivityCardFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ActivityCard', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'title',
          'summary',
          'startsAt',
          'timezone',
          'priceMinor',
          'currency',
          'photoUrl',
          'capacity',
          'spotsLeft',
          'version',
          'status',
          'community',
          'location',
          'members',
        ],
      );
      final val = ActivityCard(
        id: $checkedConvert('id', (v) => v as String),
        title: $checkedConvert('title', (v) => v as String),
        summary: $checkedConvert('summary', (v) => v as String),
        startsAt: $checkedConvert(
          'startsAt',
          (v) => DateTime.parse(v as String),
        ),
        timezone: $checkedConvert('timezone', (v) => v as String),
        priceMinor: $checkedConvert('priceMinor', (v) => (v as num).toInt()),
        currency: $checkedConvert('currency', (v) => v as String),
        photoUrl: $checkedConvert('photoUrl', (v) => v as String?),
        capacity: $checkedConvert('capacity', (v) => (v as num).toInt()),
        spotsLeft: $checkedConvert('spotsLeft', (v) => (v as num).toInt()),
        version: $checkedConvert('version', (v) => (v as num).toInt()),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$ActivityCardStatusEnumEnumMap, v),
        ),
        community: $checkedConvert(
          'community',
          (v) => PublicActivityCommunity.fromJson(v as Map<String, dynamic>),
        ),
        location: $checkedConvert(
          'location',
          (v) => ActivityCardLocation.fromJson(v as Map<String, dynamic>),
        ),
        members: $checkedConvert(
          'members',
          (v) => PublicActivityMembers.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ActivityCardToJson(ActivityCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'summary': instance.summary,
      'startsAt': instance.startsAt.toIso8601String(),
      'timezone': instance.timezone,
      'priceMinor': instance.priceMinor,
      'currency': instance.currency,
      'photoUrl': instance.photoUrl,
      'capacity': instance.capacity,
      'spotsLeft': instance.spotsLeft,
      'version': instance.version,
      'status': _$ActivityCardStatusEnumEnumMap[instance.status]!,
      'community': instance.community.toJson(),
      'location': instance.location.toJson(),
      'members': instance.members.toJson(),
    };

const _$ActivityCardStatusEnumEnumMap = {
  ActivityCardStatusEnum.open: 'open',
  ActivityCardStatusEnum.soldOut: 'sold_out',
  ActivityCardStatusEnum.started: 'started',
};
