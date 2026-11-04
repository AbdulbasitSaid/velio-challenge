// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CommunityListCWProxy {
  CommunityList communities(List<Community> communities);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CommunityList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CommunityList(...).copyWith(id: 12, name: "My name")
  /// ```
  CommunityList call({List<Community> communities});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCommunityList.copyWith(...)` or call `instanceOfCommunityList.copyWith.fieldName(value)` for a single field.
class _$CommunityListCWProxyImpl implements _$CommunityListCWProxy {
  const _$CommunityListCWProxyImpl(this._value);

  final CommunityList _value;

  @override
  CommunityList communities(List<Community> communities) =>
      call(communities: communities);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CommunityList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CommunityList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CommunityList call({Object? communities = const $CopyWithPlaceholder()}) {
    return CommunityList(
      communities:
          communities == const $CopyWithPlaceholder() || communities == null
          ? _value.communities
          // ignore: cast_nullable_to_non_nullable
          : communities as List<Community>,
    );
  }
}

extension $CommunityListCopyWith on CommunityList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCommunityList.copyWith(...)` or `instanceOfCommunityList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CommunityListCWProxy get copyWith => _$CommunityListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommunityList _$CommunityListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CommunityList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['communities']);
      final val = CommunityList(
        communities: $checkedConvert(
          'communities',
          (v) => (v as List<dynamic>)
              .map((e) => Community.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CommunityListToJson(CommunityList instance) =>
    <String, dynamic>{
      'communities': instance.communities.map((e) => e.toJson()).toList(),
    };
