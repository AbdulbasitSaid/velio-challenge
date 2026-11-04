// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CommunityPageCWProxy {
  CommunityPage community(Community community);

  CommunityPage activities(List<ActivityCard> activities);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CommunityPage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CommunityPage(...).copyWith(id: 12, name: "My name")
  /// ```
  CommunityPage call({Community community, List<ActivityCard> activities});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCommunityPage.copyWith(...)` or call `instanceOfCommunityPage.copyWith.fieldName(value)` for a single field.
class _$CommunityPageCWProxyImpl implements _$CommunityPageCWProxy {
  const _$CommunityPageCWProxyImpl(this._value);

  final CommunityPage _value;

  @override
  CommunityPage community(Community community) => call(community: community);

  @override
  CommunityPage activities(List<ActivityCard> activities) =>
      call(activities: activities);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CommunityPage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CommunityPage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CommunityPage call({
    Object? community = const $CopyWithPlaceholder(),
    Object? activities = const $CopyWithPlaceholder(),
  }) {
    return CommunityPage(
      community: community == const $CopyWithPlaceholder() || community == null
          ? _value.community
          // ignore: cast_nullable_to_non_nullable
          : community as Community,
      activities:
          activities == const $CopyWithPlaceholder() || activities == null
          ? _value.activities
          // ignore: cast_nullable_to_non_nullable
          : activities as List<ActivityCard>,
    );
  }
}

extension $CommunityPageCopyWith on CommunityPage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCommunityPage.copyWith(...)` or `instanceOfCommunityPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CommunityPageCWProxy get copyWith => _$CommunityPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommunityPage _$CommunityPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CommunityPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['community', 'activities']);
      final val = CommunityPage(
        community: $checkedConvert(
          'community',
          (v) => Community.fromJson(v as Map<String, dynamic>),
        ),
        activities: $checkedConvert(
          'activities',
          (v) => (v as List<dynamic>)
              .map((e) => ActivityCard.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CommunityPageToJson(CommunityPage instance) =>
    <String, dynamic>{
      'community': instance.community.toJson(),
      'activities': instance.activities.map((e) => e.toJson()).toList(),
    };
