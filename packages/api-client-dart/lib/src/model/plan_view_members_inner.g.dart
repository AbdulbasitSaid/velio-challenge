// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_view_members_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlanViewMembersInnerCWProxy {
  PlanViewMembersInner person(MemberPerson person);

  PlanViewMembersInner source_(PlanViewMembersInnerSource_Enum source_);

  PlanViewMembersInner invitedBy(MemberPerson? invitedBy);

  PlanViewMembersInner joinedAt(DateTime joinedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlanViewMembersInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlanViewMembersInner(...).copyWith(id: 12, name: "My name")
  /// ```
  PlanViewMembersInner call({
    MemberPerson person,
    PlanViewMembersInnerSource_Enum source_,
    MemberPerson? invitedBy,
    DateTime joinedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPlanViewMembersInner.copyWith(...)` or call `instanceOfPlanViewMembersInner.copyWith.fieldName(value)` for a single field.
class _$PlanViewMembersInnerCWProxyImpl
    implements _$PlanViewMembersInnerCWProxy {
  const _$PlanViewMembersInnerCWProxyImpl(this._value);

  final PlanViewMembersInner _value;

  @override
  PlanViewMembersInner person(MemberPerson person) => call(person: person);

  @override
  PlanViewMembersInner source_(PlanViewMembersInnerSource_Enum source_) =>
      call(source_: source_);

  @override
  PlanViewMembersInner invitedBy(MemberPerson? invitedBy) =>
      call(invitedBy: invitedBy);

  @override
  PlanViewMembersInner joinedAt(DateTime joinedAt) => call(joinedAt: joinedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlanViewMembersInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlanViewMembersInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PlanViewMembersInner call({
    Object? person = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? invitedBy = const $CopyWithPlaceholder(),
    Object? joinedAt = const $CopyWithPlaceholder(),
  }) {
    return PlanViewMembersInner(
      person: person == const $CopyWithPlaceholder() || person == null
          ? _value.person
          // ignore: cast_nullable_to_non_nullable
          : person as MemberPerson,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as PlanViewMembersInnerSource_Enum,
      invitedBy: invitedBy == const $CopyWithPlaceholder()
          ? _value.invitedBy
          // ignore: cast_nullable_to_non_nullable
          : invitedBy as MemberPerson?,
      joinedAt: joinedAt == const $CopyWithPlaceholder() || joinedAt == null
          ? _value.joinedAt
          // ignore: cast_nullable_to_non_nullable
          : joinedAt as DateTime,
    );
  }
}

extension $PlanViewMembersInnerCopyWith on PlanViewMembersInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPlanViewMembersInner.copyWith(...)` or `instanceOfPlanViewMembersInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlanViewMembersInnerCWProxy get copyWith =>
      _$PlanViewMembersInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanViewMembersInner _$PlanViewMembersInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PlanViewMembersInner', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['person', 'source', 'invitedBy', 'joinedAt'],
  );
  final val = PlanViewMembersInner(
    person: $checkedConvert(
      'person',
      (v) => MemberPerson.fromJson(v as Map<String, dynamic>),
    ),
    source_: $checkedConvert(
      'source',
      (v) => $enumDecode(_$PlanViewMembersInnerSource_EnumEnumMap, v),
    ),
    invitedBy: $checkedConvert(
      'invitedBy',
      (v) =>
          v == null ? null : MemberPerson.fromJson(v as Map<String, dynamic>),
    ),
    joinedAt: $checkedConvert('joinedAt', (v) => DateTime.parse(v as String)),
  );
  return val;
}, fieldKeyMap: const {'source_': 'source'});

Map<String, dynamic> _$PlanViewMembersInnerToJson(
  PlanViewMembersInner instance,
) => <String, dynamic>{
  'person': instance.person.toJson(),
  'source': _$PlanViewMembersInnerSource_EnumEnumMap[instance.source_]!,
  'invitedBy': instance.invitedBy?.toJson(),
  'joinedAt': instance.joinedAt.toIso8601String(),
};

const _$PlanViewMembersInnerSource_EnumEnumMap = {
  PlanViewMembersInnerSource_Enum.direct: 'direct',
  PlanViewMembersInnerSource_Enum.vouch: 'vouch',
  PlanViewMembersInnerSource_Enum.public: 'public',
};
