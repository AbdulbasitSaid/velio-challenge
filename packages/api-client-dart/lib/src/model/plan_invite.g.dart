// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_invite.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlanInviteCWProxy {
  PlanInvite id(String id);

  PlanInvite rail(PlanInviteRailEnum rail);

  PlanInvite inviteeName(String? inviteeName);

  PlanInvite createdBy(MemberPerson createdBy);

  PlanInvite status(InviteStatus status);

  PlanInvite opens(int opens);

  PlanInvite claims(int claims);

  PlanInvite paused(bool paused);

  PlanInvite pausedReason(PauseReason? pausedReason);

  PlanInvite createdAt(DateTime createdAt);

  PlanInvite code(String? code);

  PlanInvite link(String? link);

  PlanInvite note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlanInvite(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlanInvite(...).copyWith(id: 12, name: "My name")
  /// ```
  PlanInvite call({
    String id,
    PlanInviteRailEnum rail,
    String? inviteeName,
    MemberPerson createdBy,
    InviteStatus status,
    int opens,
    int claims,
    bool paused,
    PauseReason? pausedReason,
    DateTime createdAt,
    String? code,
    String? link,
    String? note,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPlanInvite.copyWith(...)` or call `instanceOfPlanInvite.copyWith.fieldName(value)` for a single field.
class _$PlanInviteCWProxyImpl implements _$PlanInviteCWProxy {
  const _$PlanInviteCWProxyImpl(this._value);

  final PlanInvite _value;

  @override
  PlanInvite id(String id) => call(id: id);

  @override
  PlanInvite rail(PlanInviteRailEnum rail) => call(rail: rail);

  @override
  PlanInvite inviteeName(String? inviteeName) => call(inviteeName: inviteeName);

  @override
  PlanInvite createdBy(MemberPerson createdBy) => call(createdBy: createdBy);

  @override
  PlanInvite status(InviteStatus status) => call(status: status);

  @override
  PlanInvite opens(int opens) => call(opens: opens);

  @override
  PlanInvite claims(int claims) => call(claims: claims);

  @override
  PlanInvite paused(bool paused) => call(paused: paused);

  @override
  PlanInvite pausedReason(PauseReason? pausedReason) =>
      call(pausedReason: pausedReason);

  @override
  PlanInvite createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  PlanInvite code(String? code) => call(code: code);

  @override
  PlanInvite link(String? link) => call(link: link);

  @override
  PlanInvite note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlanInvite(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlanInvite(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PlanInvite call({
    Object? id = const $CopyWithPlaceholder(),
    Object? rail = const $CopyWithPlaceholder(),
    Object? inviteeName = const $CopyWithPlaceholder(),
    Object? createdBy = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? opens = const $CopyWithPlaceholder(),
    Object? claims = const $CopyWithPlaceholder(),
    Object? paused = const $CopyWithPlaceholder(),
    Object? pausedReason = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return PlanInvite(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      rail: rail == const $CopyWithPlaceholder() || rail == null
          ? _value.rail
          // ignore: cast_nullable_to_non_nullable
          : rail as PlanInviteRailEnum,
      inviteeName: inviteeName == const $CopyWithPlaceholder()
          ? _value.inviteeName
          // ignore: cast_nullable_to_non_nullable
          : inviteeName as String?,
      createdBy: createdBy == const $CopyWithPlaceholder() || createdBy == null
          ? _value.createdBy
          // ignore: cast_nullable_to_non_nullable
          : createdBy as MemberPerson,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as InviteStatus,
      opens: opens == const $CopyWithPlaceholder() || opens == null
          ? _value.opens
          // ignore: cast_nullable_to_non_nullable
          : opens as int,
      claims: claims == const $CopyWithPlaceholder() || claims == null
          ? _value.claims
          // ignore: cast_nullable_to_non_nullable
          : claims as int,
      paused: paused == const $CopyWithPlaceholder() || paused == null
          ? _value.paused
          // ignore: cast_nullable_to_non_nullable
          : paused as bool,
      pausedReason: pausedReason == const $CopyWithPlaceholder()
          ? _value.pausedReason
          // ignore: cast_nullable_to_non_nullable
          : pausedReason as PauseReason?,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String?,
      link: link == const $CopyWithPlaceholder()
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String?,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $PlanInviteCopyWith on PlanInvite {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPlanInvite.copyWith(...)` or `instanceOfPlanInvite.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlanInviteCWProxy get copyWith => _$PlanInviteCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanInvite _$PlanInviteFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlanInvite', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'rail',
          'inviteeName',
          'createdBy',
          'status',
          'opens',
          'claims',
          'paused',
          'pausedReason',
          'createdAt',
        ],
      );
      final val = PlanInvite(
        id: $checkedConvert('id', (v) => v as String),
        rail: $checkedConvert(
          'rail',
          (v) => $enumDecode(_$PlanInviteRailEnumEnumMap, v),
        ),
        inviteeName: $checkedConvert('inviteeName', (v) => v as String?),
        createdBy: $checkedConvert(
          'createdBy',
          (v) => MemberPerson.fromJson(v as Map<String, dynamic>),
        ),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$InviteStatusEnumMap, v),
        ),
        opens: $checkedConvert('opens', (v) => (v as num).toInt()),
        claims: $checkedConvert('claims', (v) => (v as num).toInt()),
        paused: $checkedConvert('paused', (v) => v as bool),
        pausedReason: $checkedConvert(
          'pausedReason',
          (v) => $enumDecodeNullable(_$PauseReasonEnumMap, v),
        ),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => DateTime.parse(v as String),
        ),
        code: $checkedConvert('code', (v) => v as String?),
        link: $checkedConvert('link', (v) => v as String?),
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$PlanInviteToJson(PlanInvite instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rail': _$PlanInviteRailEnumEnumMap[instance.rail]!,
      'inviteeName': instance.inviteeName,
      'createdBy': instance.createdBy.toJson(),
      'status': _$InviteStatusEnumMap[instance.status]!,
      'opens': instance.opens,
      'claims': instance.claims,
      'paused': instance.paused,
      'pausedReason': _$PauseReasonEnumMap[instance.pausedReason],
      'createdAt': instance.createdAt.toIso8601String(),
      'code': ?instance.code,
      'link': ?instance.link,
      'note': ?instance.note,
    };

const _$PlanInviteRailEnumEnumMap = {
  PlanInviteRailEnum.vouch: 'vouch',
  PlanInviteRailEnum.public: 'public',
};

const _$InviteStatusEnumMap = {
  InviteStatus.created: 'created',
  InviteStatus.opened: 'opened',
  InviteStatus.claimed: 'claimed',
  InviteStatus.expired: 'expired',
};

const _$PauseReasonEnumMap = {
  PauseReason.owner: 'owner',
  PauseReason.host: 'host',
  PauseReason.auto: 'auto',
};
