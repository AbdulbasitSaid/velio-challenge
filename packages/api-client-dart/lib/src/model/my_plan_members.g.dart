// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_plan_members.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MyPlanMembersCWProxy {
  MyPlanMembers count(int count);

  MyPlanMembers preview(List<MemberPerson> preview);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MyPlanMembers(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MyPlanMembers(...).copyWith(id: 12, name: "My name")
  /// ```
  MyPlanMembers call({int count, List<MemberPerson> preview});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMyPlanMembers.copyWith(...)` or call `instanceOfMyPlanMembers.copyWith.fieldName(value)` for a single field.
class _$MyPlanMembersCWProxyImpl implements _$MyPlanMembersCWProxy {
  const _$MyPlanMembersCWProxyImpl(this._value);

  final MyPlanMembers _value;

  @override
  MyPlanMembers count(int count) => call(count: count);

  @override
  MyPlanMembers preview(List<MemberPerson> preview) => call(preview: preview);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MyPlanMembers(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MyPlanMembers(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MyPlanMembers call({
    Object? count = const $CopyWithPlaceholder(),
    Object? preview = const $CopyWithPlaceholder(),
  }) {
    return MyPlanMembers(
      count: count == const $CopyWithPlaceholder() || count == null
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      preview: preview == const $CopyWithPlaceholder() || preview == null
          ? _value.preview
          // ignore: cast_nullable_to_non_nullable
          : preview as List<MemberPerson>,
    );
  }
}

extension $MyPlanMembersCopyWith on MyPlanMembers {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMyPlanMembers.copyWith(...)` or `instanceOfMyPlanMembers.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MyPlanMembersCWProxy get copyWith => _$MyPlanMembersCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyPlanMembers _$MyPlanMembersFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MyPlanMembers', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['count', 'preview']);
      final val = MyPlanMembers(
        count: $checkedConvert('count', (v) => (v as num).toInt()),
        preview: $checkedConvert(
          'preview',
          (v) => (v as List<dynamic>)
              .map((e) => MemberPerson.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$MyPlanMembersToJson(MyPlanMembers instance) =>
    <String, dynamic>{
      'count': instance.count,
      'preview': instance.preview.map((e) => e.toJson()).toList(),
    };
