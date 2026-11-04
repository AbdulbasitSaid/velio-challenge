// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InviteCWProxy {
  Invite id(String id);

  Invite code(String code);

  Invite link(String link);

  Invite rail(InviteRailEnum rail);

  Invite inviteeName(String? inviteeName);

  Invite note(String? note);

  Invite status(InviteStatus status);

  Invite opens(int opens);

  Invite claims(int claims);

  Invite paused(bool paused);

  Invite pausedReason(PauseReason? pausedReason);

  Invite createdBy(MemberPerson createdBy);

  Invite createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Invite(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Invite(...).copyWith(id: 12, name: "My name")
  /// ```
  Invite call({
    String id,
    String code,
    String link,
    InviteRailEnum rail,
    String? inviteeName,
    String? note,
    InviteStatus status,
    int opens,
    int claims,
    bool paused,
    PauseReason? pausedReason,
    MemberPerson createdBy,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInvite.copyWith(...)` or call `instanceOfInvite.copyWith.fieldName(value)` for a single field.
class _$InviteCWProxyImpl implements _$InviteCWProxy {
  const _$InviteCWProxyImpl(this._value);

  final Invite _value;

  @override
  Invite id(String id) => call(id: id);

  @override
  Invite code(String code) => call(code: code);

  @override
  Invite link(String link) => call(link: link);

  @override
  Invite rail(InviteRailEnum rail) => call(rail: rail);

  @override
  Invite inviteeName(String? inviteeName) => call(inviteeName: inviteeName);

  @override
  Invite note(String? note) => call(note: note);

  @override
  Invite status(InviteStatus status) => call(status: status);

  @override
  Invite opens(int opens) => call(opens: opens);

  @override
  Invite claims(int claims) => call(claims: claims);

  @override
  Invite paused(bool paused) => call(paused: paused);

  @override
  Invite pausedReason(PauseReason? pausedReason) =>
      call(pausedReason: pausedReason);

  @override
  Invite createdBy(MemberPerson createdBy) => call(createdBy: createdBy);

  @override
  Invite createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Invite(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Invite(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Invite call({
    Object? id = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
    Object? link = const $CopyWithPlaceholder(),
    Object? rail = const $CopyWithPlaceholder(),
    Object? inviteeName = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? opens = const $CopyWithPlaceholder(),
    Object? claims = const $CopyWithPlaceholder(),
    Object? paused = const $CopyWithPlaceholder(),
    Object? pausedReason = const $CopyWithPlaceholder(),
    Object? createdBy = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Invite(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      code: code == const $CopyWithPlaceholder() || code == null
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String,
      link: link == const $CopyWithPlaceholder() || link == null
          ? _value.link
          // ignore: cast_nullable_to_non_nullable
          : link as String,
      rail: rail == const $CopyWithPlaceholder() || rail == null
          ? _value.rail
          // ignore: cast_nullable_to_non_nullable
          : rail as InviteRailEnum,
      inviteeName: inviteeName == const $CopyWithPlaceholder()
          ? _value.inviteeName
          // ignore: cast_nullable_to_non_nullable
          : inviteeName as String?,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
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
      createdBy: createdBy == const $CopyWithPlaceholder() || createdBy == null
          ? _value.createdBy
          // ignore: cast_nullable_to_non_nullable
          : createdBy as MemberPerson,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $InviteCopyWith on Invite {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInvite.copyWith(...)` or `instanceOfInvite.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InviteCWProxy get copyWith => _$InviteCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invite _$InviteFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Invite', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'id',
          'code',
          'link',
          'rail',
          'inviteeName',
          'note',
          'status',
          'opens',
          'claims',
          'paused',
          'pausedReason',
          'createdBy',
          'createdAt',
        ],
      );
      final val = Invite(
        id: $checkedConvert('id', (v) => v as String),
        code: $checkedConvert('code', (v) => v as String),
        link: $checkedConvert('link', (v) => v as String),
        rail: $checkedConvert(
          'rail',
          (v) => $enumDecode(_$InviteRailEnumEnumMap, v),
        ),
        inviteeName: $checkedConvert('inviteeName', (v) => v as String?),
        note: $checkedConvert('note', (v) => v as String?),
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
        createdBy: $checkedConvert(
          'createdBy',
          (v) => MemberPerson.fromJson(v as Map<String, dynamic>),
        ),
        createdAt: $checkedConvert(
          'createdAt',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$InviteToJson(Invite instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'link': instance.link,
  'rail': _$InviteRailEnumEnumMap[instance.rail]!,
  'inviteeName': instance.inviteeName,
  'note': instance.note,
  'status': _$InviteStatusEnumMap[instance.status]!,
  'opens': instance.opens,
  'claims': instance.claims,
  'paused': instance.paused,
  'pausedReason': _$PauseReasonEnumMap[instance.pausedReason],
  'createdBy': instance.createdBy.toJson(),
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$InviteRailEnumEnumMap = {
  InviteRailEnum.vouch: 'vouch',
  InviteRailEnum.public: 'public',
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
