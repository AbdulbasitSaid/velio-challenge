// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_view.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlanViewCWProxy {
  PlanView id(String id);

  PlanView activity(PlanViewActivity activity);

  PlanView owner(MemberPerson owner);

  PlanView members(List<PlanViewMembersInner> members);

  PlanView viewer(PlanViewViewer viewer);

  PlanView invites(List<PlanInvite> invites);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlanView(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlanView(...).copyWith(id: 12, name: "My name")
  /// ```
  PlanView call({
    String id,
    PlanViewActivity activity,
    MemberPerson owner,
    List<PlanViewMembersInner> members,
    PlanViewViewer viewer,
    List<PlanInvite> invites,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPlanView.copyWith(...)` or call `instanceOfPlanView.copyWith.fieldName(value)` for a single field.
class _$PlanViewCWProxyImpl implements _$PlanViewCWProxy {
  const _$PlanViewCWProxyImpl(this._value);

  final PlanView _value;

  @override
  PlanView id(String id) => call(id: id);

  @override
  PlanView activity(PlanViewActivity activity) => call(activity: activity);

  @override
  PlanView owner(MemberPerson owner) => call(owner: owner);

  @override
  PlanView members(List<PlanViewMembersInner> members) =>
      call(members: members);

  @override
  PlanView viewer(PlanViewViewer viewer) => call(viewer: viewer);

  @override
  PlanView invites(List<PlanInvite> invites) => call(invites: invites);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlanView(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlanView(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PlanView call({
    Object? id = const $CopyWithPlaceholder(),
    Object? activity = const $CopyWithPlaceholder(),
    Object? owner = const $CopyWithPlaceholder(),
    Object? members = const $CopyWithPlaceholder(),
    Object? viewer = const $CopyWithPlaceholder(),
    Object? invites = const $CopyWithPlaceholder(),
  }) {
    return PlanView(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      activity: activity == const $CopyWithPlaceholder() || activity == null
          ? _value.activity
          // ignore: cast_nullable_to_non_nullable
          : activity as PlanViewActivity,
      owner: owner == const $CopyWithPlaceholder() || owner == null
          ? _value.owner
          // ignore: cast_nullable_to_non_nullable
          : owner as MemberPerson,
      members: members == const $CopyWithPlaceholder() || members == null
          ? _value.members
          // ignore: cast_nullable_to_non_nullable
          : members as List<PlanViewMembersInner>,
      viewer: viewer == const $CopyWithPlaceholder() || viewer == null
          ? _value.viewer
          // ignore: cast_nullable_to_non_nullable
          : viewer as PlanViewViewer,
      invites: invites == const $CopyWithPlaceholder() || invites == null
          ? _value.invites
          // ignore: cast_nullable_to_non_nullable
          : invites as List<PlanInvite>,
    );
  }
}

extension $PlanViewCopyWith on PlanView {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPlanView.copyWith(...)` or `instanceOfPlanView.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlanViewCWProxy get copyWith => _$PlanViewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanView _$PlanViewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlanView', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'activity',
          'owner',
          'members',
          'viewer',
          'invites',
        ],
      );
      final val = PlanView(
        id: $checkedConvert('id', (v) => v as String),
        activity: $checkedConvert(
          'activity',
          (v) => PlanViewActivity.fromJson(v as Map<String, dynamic>),
        ),
        owner: $checkedConvert(
          'owner',
          (v) => MemberPerson.fromJson(v as Map<String, dynamic>),
        ),
        members: $checkedConvert(
          'members',
          (v) => (v as List<dynamic>)
              .map(
                (e) => PlanViewMembersInner.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        viewer: $checkedConvert(
          'viewer',
          (v) => PlanViewViewer.fromJson(v as Map<String, dynamic>),
        ),
        invites: $checkedConvert(
          'invites',
          (v) => (v as List<dynamic>)
              .map((e) => PlanInvite.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PlanViewToJson(PlanView instance) => <String, dynamic>{
  'id': instance.id,
  'activity': instance.activity.toJson(),
  'owner': instance.owner.toJson(),
  'members': instance.members.map((e) => e.toJson()).toList(),
  'viewer': instance.viewer.toJson(),
  'invites': instance.invites.map((e) => e.toJson()).toList(),
};
