// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_activity_members.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicActivityMembersCWProxy {
  PublicActivityMembers count(int count);

  PublicActivityMembers preview(List<PublicPerson> preview);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicActivityMembers(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicActivityMembers(...).copyWith(id: 12, name: "My name")
  /// ```
  PublicActivityMembers call({int count, List<PublicPerson> preview});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPublicActivityMembers.copyWith(...)` or call `instanceOfPublicActivityMembers.copyWith.fieldName(value)` for a single field.
class _$PublicActivityMembersCWProxyImpl
    implements _$PublicActivityMembersCWProxy {
  const _$PublicActivityMembersCWProxyImpl(this._value);

  final PublicActivityMembers _value;

  @override
  PublicActivityMembers count(int count) => call(count: count);

  @override
  PublicActivityMembers preview(List<PublicPerson> preview) =>
      call(preview: preview);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PublicActivityMembers(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PublicActivityMembers(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PublicActivityMembers call({
    Object? count = const $CopyWithPlaceholder(),
    Object? preview = const $CopyWithPlaceholder(),
  }) {
    return PublicActivityMembers(
      count: count == const $CopyWithPlaceholder() || count == null
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      preview: preview == const $CopyWithPlaceholder() || preview == null
          ? _value.preview
          // ignore: cast_nullable_to_non_nullable
          : preview as List<PublicPerson>,
    );
  }
}

extension $PublicActivityMembersCopyWith on PublicActivityMembers {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPublicActivityMembers.copyWith(...)` or `instanceOfPublicActivityMembers.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicActivityMembersCWProxy get copyWith =>
      _$PublicActivityMembersCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicActivityMembers _$PublicActivityMembersFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PublicActivityMembers', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['count', 'preview']);
  final val = PublicActivityMembers(
    count: $checkedConvert('count', (v) => (v as num).toInt()),
    preview: $checkedConvert(
      'preview',
      (v) => (v as List<dynamic>)
          .map((e) => PublicPerson.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$PublicActivityMembersToJson(
  PublicActivityMembers instance,
) => <String, dynamic>{
  'count': instance.count,
  'preview': instance.preview.map((e) => e.toJson()).toList(),
};
